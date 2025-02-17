//
//  UplynkAdIntegration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import OSLog

protocol Player: AnyObject {
    var currentTime: Double { get }
    var source: SourceDescription? { get set }
    
    func addEventListener<E>(type: EventType<E>, listener: @escaping (E) -> ()) -> EventListener where E: EventProtocol
    func setCurrentTime(_ newValue: Double, completionHandler: ((Any?, (Error)?) -> Void)?)
}

extension THEOplayer: Player {}

class UplynkAdIntegration: ServerSideAdIntegrationHandler {
    
    enum State: Equatable {
        case playingContent
        case internallyInitiatedSeekInProgress
        case playingSeekedOnAdBreak
        case playingSeekedOverAdBreak(seekedTime: Double, hasSeekedOnToThePlayingAdBreak: Bool)
    }
    
    static let INTEGRATION_ID: String = "uplynk"

    private let player: Player
    private weak var eventListener: UplynkEventListener?
    private let uplynkAPI: UplynkAPIProtocol.Type
    private let controller: ServerSideAdIntegrationController
    private let configuration: UplynkConfiguration
    private(set) var isSettingSource: Bool = false
    private var pingScheduler: PingSchedulerProtocol?

    private var pingSchedulerFactory: PingSchedulerFactory.Type
    private var adHandlerFactory: AdHandlerFactory.Type
    private var adSchedulerFactory: AdSchedulerFactory.Type
    private var adScheduler: AdSchedulerProtocol?
    private var state: State = .playingContent
    private var isSeekingInProgress: Bool = false

    // MARK: Private event listener's
    
    private var timeUpdateEventListener: EventListener?
    private var seekingEventListener: EventListener?
    private var seekedEventListener: EventListener?
    private var playEventListener: EventListener?

    init(uplynkAPI: UplynkAPIProtocol.Type = UplynkAPI.self,
         player: Player,
         controller: ServerSideAdIntegrationController,
         configuration: UplynkConfiguration,
         eventListener: UplynkEventListener? = nil,
         adSchedulerFactory: AdSchedulerFactory.Type = AdScheduler.self,
         adHandlerFactory: AdHandlerFactory.Type = AdHandler.self,
         pingSchedulerFactory: PingSchedulerFactory.Type = PingScheduler.self
    ) {
        self.eventListener = eventListener
        self.uplynkAPI = uplynkAPI
        self.player = player
        self.controller = controller
        self.configuration = configuration
        self.adSchedulerFactory = adSchedulerFactory
        self.adHandlerFactory = adHandlerFactory
        self.pingSchedulerFactory = pingSchedulerFactory

        // Setup event listner's to schedule ping
        timeUpdateEventListener = player.addEventListener(type: PlayerEventTypes.TIME_UPDATE) { [weak self] event in
            os_log(.debug, log: .adIntegration, "TIME_UPDATE: Received event at %f", event.currentTime)
            
            guard let self, self.isSeekingInProgress == false else { return }
            self.pingScheduler?.onTimeUpdate(time: event.currentTime)
            self.adScheduler?.onTimeUpdate(time: event.currentTime)
            
            if self.adScheduler?.isPlayingAd == false, self.configuration.skippedAdStrategy != .playNone {
                if case let .playingSeekedOverAdBreak(seekedTime: seekedTime, hasSeekedOnToThePlayingAdBreak: hasSeekedOnToThePlayingAdBreak) = self.state {
                    os_log(.debug, log: .adIntegration, "TIME_UPDATE: Finished playing seeked over ad", event.currentTime)
                    self.handleCompletionWhenPlayingSeekedOverAdBreak(seekedTime, hasUserSeekedOnToTheLastPlayedAdBreak: hasSeekedOnToThePlayingAdBreak)
                } else if case .playingSeekedOnAdBreak = self.state {
                    os_log(.debug, log: .adIntegration, "TIME_UPDATE: Finished playing seeked on adbreak", event.currentTime)
                    self.state = .playingContent
                }
            }
        }
        
        seekingEventListener = player.addEventListener(type: PlayerEventTypes.SEEKING) { [weak self] event in
            guard let self else { return }

            self.pingScheduler?.onSeeking(time: event.currentTime)
            os_log(.debug,log: .adIntegration, "SEEKING: Received seeking event: %f", event.currentTime)
            if self.state != .internallyInitiatedSeekInProgress {
                os_log(.debug,log: .adIntegration, "SEEKING: Setting user initiated seeking in progress: %f", event.currentTime)
                self.isSeekingInProgress = true
            }
        }
        
        seekedEventListener = player.addEventListener(type: PlayerEventTypes.SEEKED) { [weak self] event in
            guard let self else { return }
            self.pingScheduler?.onSeeked(time: event.currentTime)
            os_log(.debug,log: .adIntegration, "SEEKED: Pass seeked time to ping scheduler %f", event.currentTime)
            if self.isSeekingInProgress {
                os_log(.debug,log: .adIntegration, "SEEKED: Reset user initiated seeking state: %f", event.currentTime)
                self.isSeekingInProgress = false
            }

            guard self.state != .internallyInitiatedSeekInProgress else {
                os_log(.debug,log: .adIntegration, "SEEKED: Returning a seek initiated internally")
                return
            }
            os_log(.debug,log: .adIntegration, "SEEKED: Received seeked event: %f", event.currentTime)

            let playSeekedOverAdBreak = { (seekedTime: Double, adBreakOffset: Double) in
                self.state = .internallyInitiatedSeekInProgress
                self.seek(to: adBreakOffset) { [weak self] _, error in
                    guard let self, error == nil else {
                        os_log(.debug,log: .adIntegration, "SEEKED: Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    
                    // If seeked on to an adbreak, play it from the beginning
                    let updatedSeekedTime = self.adScheduler?.adBreakOffsetIfAdBreakContains(time: seekedTime) ?? seekedTime
                    self.state = .playingSeekedOverAdBreak(seekedTime: updatedSeekedTime,
                                                           hasSeekedOnToThePlayingAdBreak: updatedSeekedTime == adBreakOffset)
                    os_log(.debug,log: .adIntegration, "SEEKED: Setting state to playing seeked over adbreak with actual seek time %f", seekedTime)
                }
            }
            switch self.configuration.skippedAdStrategy {
            case .playAll:
                if let adBreakOffset = self.adScheduler?.firstUnwatchedAdBreakOffset(before: event.currentTime) {
                    os_log(.debug,log: .adIntegration, "SEEKED: Playing first unwatched ad break at: %f", adBreakOffset)
                    playSeekedOverAdBreak(event.currentTime, adBreakOffset)
                    return
                }
            case .playLast:
                if let adBreakOffset = self.adScheduler?.lastUnwatchedAdBreakOffset(before: event.currentTime) {
                    os_log(.debug,log: .adIntegration, "SEEKED: Playing last unwatched ad break at: %f", adBreakOffset)
                    playSeekedOverAdBreak(event.currentTime, adBreakOffset)
                    return
                }
            case .playNone:
                // When seeked on to an AdBreak and skip ad strategy is `play none` - seek to the end
                if let adBreakEndTime = self.adScheduler?.adBreakEndTimeIfAdBreakContains(time: event.currentTime) {
                    os_log(.debug,log: .adIntegration, "SEEKED: Seek to end of adbreak(strategy play none): %f", adBreakEndTime)
                    self.state = .internallyInitiatedSeekInProgress
                    self.seek(to: adBreakEndTime) { [weak self] _, error in
                        guard error == nil else {
                            os_log(.debug,log: .adIntegration, "SEEKED: Failed to seek to end of adbreak with error: %@", error?.localizedDescription ?? "N/A")
                            self?.state = .playingContent
                            return
                        }
                        self?.state = .playingContent
                        os_log(.debug,log: .adIntegration, "SEEKED: Reset state to playing content")
                    }
                    return
                }
            }
            
            // When seeked on to an AdBreak (even if it is already watched); Play Adbreak from beginning
            // This scenario applies only to `play all` or `play last` strategies
            // This also captures scenario where the user seeked onto an unwatched `AdBreak` and by the time seeked
            // event arrives, the `AdBreak` is already set to state `started`. Here `firstUnwatchedAdBreakOffset` or
            // `lastUnwatchedAdBreakOffset` will be returned `false` for playAll and playNone strategy.
            // However the below check ensures the AdBreak is still played from the beginning.
            if let adBreakStartTime = self.adScheduler?.adBreakOffsetIfAdBreakContains(time: event.currentTime) {
                os_log(.debug,log: .adIntegration, "SEEKED: Seek to start of adbreak: %f", adBreakStartTime)
                self.state = .internallyInitiatedSeekInProgress
                self.seek(to: adBreakStartTime) { [weak self] _, error in
                    guard error == nil else {
                        os_log(.debug,log: .adIntegration, "SEEKED: Failed to seek to start of adbreak with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    self?.state = .playingSeekedOnAdBreak
                    os_log(.debug,log: .adIntegration, "SEEKED: Reset state to playing content")
                }
                return
            }
        }
        
        playEventListener = player.addEventListener(type: PlayerEventTypes.PLAY) {  [weak self] event in
            self?.pingScheduler?.onStart(time: event.currentTime)
            os_log(.debug,log: .adIntegration, "PLAY: Received play event at: %f", event.currentTime)
        }
    }

    // Implements ServerSideAdIntegrationHandler.setSource
    func setSource(source: SourceDescription) -> Bool {
        // copy the passed SourceDescription; we don't want to modify the original
        let sourceDescription: SourceDescription = source.createCopy()
        let isUplynkSSAI: (TypedSource) -> Bool = { $0.ssai as? UplynkSSAIConfiguration != nil }

        guard let typedSource: TypedSource = sourceDescription.sources.first(where: isUplynkSSAI),
           let uplynkConfig: UplynkSSAIConfiguration = typedSource.ssai as? UplynkSSAIConfiguration else {
            return false
        }
        let urlBuilder = UplynkSSAIURLBuilder(ssaiConfiguration: uplynkConfig)
        let preplayURL: String = switch uplynkConfig.assetType {
        case .asset:
            urlBuilder.buildPreplayVODURL()
        case .channel:
            urlBuilder.buildPreplayLiveURL()
        }
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let preplayResponse = try await self.onPrePlayRequest(preplaySrcURL: preplayURL, assetType: uplynkConfig.assetType)
                let adScheduler = self.createAdScheduler(preplayResponse: preplayResponse)
                if uplynkConfig.pingFeature != .noPing {
                    os_log(.debug,log: .adIntegration, "Scheduling ping")
                    pingScheduler = self.pingSchedulerFactory.make(urlBuilder: urlBuilder,
                                                                   prefix: preplayResponse.prefix,
                                                                   sessionId: preplayResponse.sid,
                                                                   listener: eventListener,
                                                                   controller: self.controller,
                                                                   adScheduler: adScheduler, 
                                                                   uplynkApiType: uplynkAPI)
                }
                self.adScheduler = adScheduler
                self.onPrePlayResponse(response: preplayResponse,
                                       sourceDescription: sourceDescription,
                                       typedSource: typedSource,
                                       ssaiConfiguration: uplynkConfig)
            } catch {
                let uplynkError = UplynkError(
                    url: preplayURL,
                    description: error.localizedDescription,
                    code: .UPLYNK_ERROR_CODE_PREPLAY_REQUEST_FAILED)
                eventListener?.onError(uplynkError)
                controller.error(error: uplynkError)
            }
        }
        
        return true
    }
    
    // TODO: Check whether the adbreak or the current ad need to be skipped, when `skipAd` is called and remove the unused code
    private static let SKIP_ADBREAK = false
    func skipAd(ad: Ad) -> Bool {
        if Self.SKIP_ADBREAK {
            os_log(.debug,log: .adIntegration, "SKIP_AD: Handling skip adbreak")
            guard isSkippableAdBreak(),
                  let adBreakStartTime = adScheduler?.currentAdBreakStartTime,
                  player.currentTime >= adBreakStartTime + Double(configuration.defaultSkipOffset)
            else {
                return true
            }

            if case let .playingSeekedOverAdBreak(seekedTime: seekedTime, hasSeekedOnToThePlayingAdBreak: hasSeekedOnToThePlayingAdBreak) = state,
                configuration.skippedAdStrategy != .playNone {
                handleSkipWhenPlayingSeekedOverAdBreak(seekedTime, hasUserSeekedOnToTheLastPlayedAdBreak: hasSeekedOnToThePlayingAdBreak)
            } else if let seekToTime = adScheduler?.currentAdBreakEndTime {
                os_log(.debug,log: .adIntegration, "SKIP_AD: Skipping on to end of adbreak %f", seekToTime)
                state = .internallyInitiatedSeekInProgress
                seek(to: seekToTime) { [weak self] _, error in
                    guard error == nil else {
                        os_log(.debug,log: .adIntegration, "SKIP_AD: Failed to seek(skipAd) with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    self?.state = .playingContent
                    os_log(.debug,log: .adIntegration, "SKIP_AD: Reset state to playing content")
                }
            }
            return true
        }
        
        os_log(.debug,log: .adIntegration, "SKIP_AD: Handling skip ad")
        guard isSkippable(ad: ad),
              let adStartTime = adScheduler?.currentAdStartTime,
              player.currentTime >= adStartTime + Double(configuration.defaultSkipOffset) else {
            os_log(.debug,log: .adIntegration, "SKIP_AD: Exiting skip ad")
            return true
        }
        
        if case let .playingSeekedOverAdBreak(seekedTime: seekedTime, hasSeekedOnToThePlayingAdBreak: hasSeekedOnToThePlayingAdBreak) = state,
            configuration.skippedAdStrategy != .playNone, adScheduler?.isPlayingLastAdInAdBreak == true {
            handleSkipWhenPlayingSeekedOverAdBreak(seekedTime, hasUserSeekedOnToTheLastPlayedAdBreak: hasSeekedOnToThePlayingAdBreak)
        } else if let seekToTime = adScheduler?.currentAdEndTime {
            os_log(.debug,log: .adIntegration, "SKIP_AD: Skipping on to the next ad %f", seekToTime)
            let stateBeforeSkippingAd = state
            state = .internallyInitiatedSeekInProgress
            seek(to: seekToTime) { [weak self] _, error in
                guard error == nil else {
                    os_log(.debug,log: .adIntegration, "SKIP_AD: Failed to seek(skipAd) with error: %@", error?.localizedDescription ?? "N/A")
                    self?.state = .playingContent
                    return
                }
                self?.state = stateBeforeSkippingAd
                os_log(.debug,log: .adIntegration, "SKIP_AD: Reset state to playing content")
            }
        }
        return true
    }
    
    func resetSource() -> Bool {
        pingScheduler = nil
        adScheduler = nil
        return true
    }
    
    func destroy() {
        pingScheduler = nil
        adScheduler = nil
    }

    private func createAdScheduler(preplayResponse: PrePlayResponseProtocol) -> AdSchedulerProtocol {
        let adBreaks: [UplynkAdBreak] = (preplayResponse as? PrePlayVODResponse)?.ads.breaks ?? []
        let adHandler = adHandlerFactory.makeAdHandler(controller: controller, skipOffset: configuration.defaultSkipOffset)
        return adSchedulerFactory.makeAdScheduler(adBreaks: adBreaks, adHandler: adHandler)
    }
    
    private func onPrePlayRequest(preplaySrcURL: String, assetType: UplynkSSAIConfiguration.AssetType) async throws -> PrePlayResponseProtocol {
        switch assetType {
        case .asset:
            return try await uplynkAPI.requestVOD(preplaySrcURL: preplaySrcURL)
        case .channel:
            return try await uplynkAPI.requestLive(preplaySrcURL: preplaySrcURL)
        }
    }
    
    private func onAssetInfoRequest(assetInfoURL: String) async throws -> AssetInfoResponse {
        return try await uplynkAPI.requestAssetInfo(url: assetInfoURL)
    }
    
    private func performAssetInfoRequests(ssaiConfiguration: UplynkSSAIConfiguration, preplayResponse: PrePlayResponseProtocol) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            let assetInfoURLs = UplynkSSAIURLBuilder(ssaiConfiguration: ssaiConfiguration)
                .buildAssetInfoURLs(sessionID: preplayResponse.sid, prefix: preplayResponse.prefix)
            assetInfoURLs.forEach { url in
                taskGroup.addTask { @MainActor in
                    do {
                        let assetInfoResponse = try await self.onAssetInfoRequest(assetInfoURL: url)
                        self.onAssetInfoResponse(assetInfoResponse)
                    } catch {
                        let uplynkError = UplynkError(
                            url: url,
                            description: error.localizedDescription,
                            code: .UPLYNK_ERROR_CODE_ASSET_INFO_REQUEST_FAILED)
                        self.eventListener?.onError(uplynkError)
                        self.controller.error(error: uplynkError)
                    }
                }
                
            }
        }
    }
    
    private func onAssetInfoResponse(_ response: AssetInfoResponse) {
        eventListener?.onAssetInfoResponse(response)
    }
    
    private func onPrePlayResponse(response: PrePlayResponseProtocol,
                                   sourceDescription: SourceDescription,
                                   typedSource: TypedSource,
                                   ssaiConfiguration: UplynkSSAIConfiguration) {
        os_log(.debug,log: .adIntegration, "Received preplay response")
        let playURL = if ssaiConfiguration.playbackURLParametersString.isEmpty == false {
            "\(response.playURL)?\(ssaiConfiguration.playbackURLParametersString)"
        } else {
            response.playURL
        }
        os_log(.debug,log: .adIntegration, "Play url: %@", playURL)
        typedSource.src = URL(string: playURL)!
        if let drm = response.drm, drm.required {
            typedSource.drm = FairPlayDRMConfiguration(customIntegrationId: UplynkAdIntegration.INTEGRATION_ID,
                                                       licenseAcquisitionURL: "",
                                                       certificateURL: drm.fairplayCertificateURL)
        }
        player.source = sourceDescription
        
        if let liveResponse = response as? PrePlayLiveResponse {
            eventListener?.onPreplayLiveResponse(liveResponse)
        } else if let vodResponse = response as? PrePlayVODResponse {
            eventListener?.onPreplayVODResponse(vodResponse)
        }
        // Perform AssetInfo requests
        if (ssaiConfiguration.assetInfo) {
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.performAssetInfoRequests(ssaiConfiguration: ssaiConfiguration, preplayResponse: response)
            }
        }
    }
    
    private func seek(to offset: Double, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        player.setCurrentTime(offset, completionHandler: completionHandler)
    }
    
    private func isSkippable(ad: Ad) -> Bool {
        ad.skipOffset != -1
    }
    
    private func isSkippableAdBreak() -> Bool {
        configuration.defaultSkipOffset != -1
    }
    
    private func handleCompletionWhenPlayingSeekedOverAdBreak(_ seekedTime: Double, hasUserSeekedOnToTheLastPlayedAdBreak: Bool) {
        os_log(.debug,log: .adIntegration, "handleCompletionWhenPlayingSeekedOverAdBreak")
        switch configuration.skippedAdStrategy {
        case .playAll:
            // Check is there is a followup ad in the list to play?
            if let adBreakOffset = adScheduler?.firstUnwatchedAdBreakOffset(before: seekedTime) {
                // Play next ad
                os_log(.debug,log: .adIntegration, "Seek to next ad: %f", adBreakOffset)
                state = .internallyInitiatedSeekInProgress
                // If seeked on to an adbreak, play it from the beginning
                let updatedSeekedTime = adScheduler?.adBreakOffsetIfAdBreakContains(time: seekedTime) ?? seekedTime
                seek(to: adBreakOffset) { [weak self] _, error in
                    guard let self, error == nil else {
                        os_log(.debug,log: .adIntegration, "Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    
                    self.state = .playingSeekedOverAdBreak(seekedTime: updatedSeekedTime,
                                                           hasSeekedOnToThePlayingAdBreak: updatedSeekedTime == adBreakOffset)
                    os_log(.debug,log: .adIntegration, "Setting state to playing seeked over adbreak with stored seek time %f", seekedTime)
                }
            } else {
                os_log(.debug,log: .adIntegration, "No more ads to watch for `play all` strategy")
                if hasUserSeekedOnToTheLastPlayedAdBreak {
                    os_log(.debug,log: .adIntegration, "Skip seeking as the user has seeked on to the last played ad")
                } else {
                    os_log(.debug,log: .adIntegration, "Seek to point: %f", seekedTime)
                    state = .internallyInitiatedSeekInProgress
                    seek(to: seekedTime) { [weak self] _, error in
                        guard error == nil else {
                            os_log(.debug,log: .adIntegration, "Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                            self?.state = .playingContent
                            return
                        }
                        self?.state = .playingContent
                        os_log(.debug,log: .adIntegration, "Reset state to playing content")
                    }
                }
            }
        case .playLast:
            // We have already played the last ad from on `seeked` function
            // Reset the state and seek to original seek time
            os_log(.debug,log: .adIntegration, "No more ads to watch for `play last` strategy")
            if hasUserSeekedOnToTheLastPlayedAdBreak {
                os_log(.debug,log: .adIntegration, "Skip seeking as the user has seeked on to an ad")
            } else {
                os_log(.debug,log: .adIntegration, "Seek to point: %f", seekedTime)
                state = .internallyInitiatedSeekInProgress
                seek(to: seekedTime) { [weak self] _, error in
                    guard error == nil else {
                        os_log(.debug,log: .adIntegration, "Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    self?.state = .playingContent
                }
            }
        default:
            break
        }
    }
    
    private func handleSkipWhenPlayingSeekedOverAdBreak(_ seekedTime: Double, hasUserSeekedOnToTheLastPlayedAdBreak: Bool) {
        os_log(.debug,log: .adIntegration, "handleSkipWhenPlayingSeekedOverAdBreak")
        switch configuration.skippedAdStrategy {
        case .playAll:
            // Check is there is a followup ad in the list to play?
            if let adBreakOffset = adScheduler?.firstUnwatchedAdBreakOffset(before: seekedTime) {
                // Play next adbreak
                os_log(.debug,log: .adIntegration, "Seek to next adbreak: %f", adBreakOffset)
                state = .internallyInitiatedSeekInProgress
                // If seeked on to an adbreak, play it from the beginning
                let updatedSeekedTime = adScheduler?.adBreakOffsetIfAdBreakContains(time: seekedTime) ?? seekedTime
                seek(to: adBreakOffset) { [weak self] _, error in
                    guard let self, error == nil else {
                        os_log(.debug,log: .adIntegration, "Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    
                    self.state = .playingSeekedOverAdBreak(seekedTime: updatedSeekedTime,
                                                           hasSeekedOnToThePlayingAdBreak: updatedSeekedTime == adBreakOffset)
                    os_log(.debug,log: .adIntegration, "Setting state to playing seeked over adbreak with stored seek time %f", seekedTime)
                }
            } else {
                os_log(.debug,log: .adIntegration, "No more ads to watch for `play all` strategy")
                if hasUserSeekedOnToTheLastPlayedAdBreak, let seekToTime = adScheduler?.currentAdBreakEndTime {
                    os_log(.debug,log: .adIntegration, "Seek to the end of the AdBreak")
                    state = .internallyInitiatedSeekInProgress
                    seek(to: seekToTime) { [weak self] _, error in
                        guard error == nil else {
                            os_log(.debug,log: .adIntegration, "Failed to seek(skipAd) with error: %@", error?.localizedDescription ?? "N/A")
                            self?.state = .playingContent
                            return
                        }
                        self?.state = .playingContent
                        os_log(.debug,log: .adIntegration, "Reset state to playing content")
                    }
                } else {
                    os_log(.debug,log: .adIntegration, "Seek to point: %f", seekedTime)
                    state = .internallyInitiatedSeekInProgress
                    seek(to: seekedTime) { [weak self] _, error in
                        guard error == nil else {
                            os_log(.debug,log: .adIntegration, "Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                            self?.state = .playingContent
                            return
                        }
                        self?.state = .playingContent
                        os_log(.debug,log: .adIntegration, "Reset state to playing content")
                    }
                }
            }
        case .playLast:
            // We have already played the last ad from on `seeked` function
            // Reset the state and seek to original seek time
            os_log(.debug,log: .adIntegration, "No more ads to watch for `play last` strategy")
            if hasUserSeekedOnToTheLastPlayedAdBreak, let seekToTime = adScheduler?.currentAdBreakEndTime {
                os_log(.debug,log: .adIntegration, "Seek to the end of the AdBreak")
                state = .internallyInitiatedSeekInProgress
                seek(to: seekToTime) { [weak self] _, error in
                    guard error == nil else {
                        os_log(.debug,log: .adIntegration, "Failed to seek(skipAd) with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    self?.state = .playingContent
                    os_log(.debug,log: .adIntegration, "Reset state to playing content")
                }
            } else {
                os_log(.debug,log: .adIntegration, "Seek to point: %f", seekedTime)
                state = .internallyInitiatedSeekInProgress
                seek(to: seekedTime) { [weak self] _, error in
                    guard error == nil else {
                        os_log(.debug,log: .adIntegration, "Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                        self?.state = .playingContent
                        return
                    }
                    self?.state = .playingContent
                }
            }
        default:
            break
        }
    }
}
