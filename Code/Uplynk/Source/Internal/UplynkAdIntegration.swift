//
//  UplynkAdIntegration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import OSLog

class UplynkAdIntegration: ServerSideAdIntegrationHandler {
    
    enum State: Equatable {
        case playingContent
        case seekingToAdStart
        case playingSeekedOverAdBreak(seekedTime: Double, hasSeekedOnToAd: Bool)
    }
    
    static let INTEGRATION_ID: String = "uplynk"

    private let player: THEOplayer
    private weak var eventListener: UplynkEventListener?
    private let uplynkAPI: UplynkAPIProtocol.Type
    private let controller: ServerSideAdIntegrationController
    private let configuration: UplynkConfiguration
    private(set) var isSettingSource: Bool = false
    private var pingScheduler: PingScheduler?

    private var adScheduler: AdScheduler?
    private var state: State = .playingContent

    // MARK: Private event listener's
    
    private var timeUpdateEventListener: EventListener?
    private var seekingEventListener: EventListener?
    private var seekedEventListener: EventListener?
    private var playEventListener: EventListener?

    init(uplynkAPI: UplynkAPIProtocol.Type = UplynkAPI.self,
         player: THEOplayer,
         controller: ServerSideAdIntegrationController,
         configuration: UplynkConfiguration,
         eventListener: UplynkEventListener? = nil) {
        self.eventListener = eventListener
        self.uplynkAPI = uplynkAPI
        self.player = player
        self.controller = controller
        self.configuration = configuration
        
        // Setup event listner's to schedule ping
        timeUpdateEventListener = player.addEventListener(type: PlayerEventTypes.TIME_UPDATE) { [weak self] event in
            os_log(.debug, log: .adIntegration, "Time update event: %f", event.currentTime)
            guard let self else { return }
            self.pingScheduler?.onTimeUpdate(time: event.currentTime)
            self.adScheduler?.onTimeUpdate(time: event.currentTime)
            
            if case let .playingSeekedOverAdBreak(seekedTime: seekedTime, hasSeekedOnToAd: hasSeekedOnToAd) = self.state,
                self.adScheduler?.isPlayingAd == false,
                self.configuration.skippedAdStrategy != .playNone {
                
                guard self.state != .seekingToAdStart else {
                    return
                }
                
                switch self.configuration.skippedAdStrategy {
                case .playAll:
                    // Check is there is a followup ad in the list to play?
                    if let adBreakOffset = self.adScheduler?.firstUnwatchedAdBreakOffset(before: seekedTime) {
                        // Play next ad
                        os_log(.debug,log: .adIntegration, "TIME_UPDATE: Seek to next ad: %f", adBreakOffset)
                        self.seek(to: adBreakOffset)
                    } else {
                        os_log(.debug,log: .adIntegration, "TIME_UPDATE: No more ads to watch for `play all` strategy")
                        if hasSeekedOnToAd {
                            os_log(.debug,log: .adIntegration, "TIME_UPDATE: Skip seeking as the user has seeked on to an ad")
                        } else {
                            os_log(.debug,log: .adIntegration, "TIME_UPDATE: Seek to point: %f", seekedTime)
                            self.seek(to: seekedTime) { [weak self] _, error in
                                guard error == nil else {
                                    os_log(.debug,log: .adIntegration, "TIME_UPDATE: Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                                    return
                                }
                                self?.state = .playingContent
                                os_log(.debug,log: .adIntegration, "TIME_UPDATE: Reset state to playing content")
                            }
                        }
                    }
                case .playLast:
                    // We have already played the last ad from on `seeked` function
                    // Reset the state and seek to original seek time
                    os_log(.debug,log: .adIntegration, "TIME_UPDATE: No more ads to watch for `play last` strategy")
                    if hasSeekedOnToAd {
                        os_log(.debug,log: .adIntegration, "TIME_UPDATE: Skip seeking as the user has seeked on to an ad")
                    } else {
                        os_log(.debug,log: .adIntegration, "TIME_UPDATE: Seek to point: %f", seekedTime)
                        self.seek(to: seekedTime) { [weak self] _, error in
                            guard error == nil else {
                                os_log(.debug,log: .adIntegration, "TIME_UPDATE: Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                                return
                            }
                            self?.state = .playingContent
                        }
                    }
                default:
                    break
                }
            }
            
            // Seek to end time of adbreak if its already watched
            if let adBreakEndTime = self.adScheduler?.adBreakEndTimeIfPlayingAlreadyWatchedAdBreak(for: event.currentTime) {
                os_log(.debug,log: .adIntegration, "TIME_UPDATE: Already watched adbreak, seek to: %f", adBreakEndTime)
                self.seek(to: adBreakEndTime)
            }
        }
        
        seekingEventListener = player.addEventListener(type: PlayerEventTypes.SEEKING) { [weak self] event in
            self?.pingScheduler?.onSeeking(time: event.currentTime)
            os_log(.debug,log: .adIntegration, "SEEKING: Received seeking event: %f", event.currentTime)
        }
        
        seekedEventListener = player.addEventListener(type: PlayerEventTypes.SEEKED) { [weak self] event in
            guard let self, self.state != .seekingToAdStart else { return }
            os_log(.debug,log: .adIntegration, "SEEKED: Received seeked event: %f", event.currentTime)

            if self.state == .playingContent {
                self.pingScheduler?.onSeeked(time: event.currentTime)
                os_log(.debug,log: .adIntegration, "SEEKED: Delegating seeked time to ping scheduler %f", event.currentTime)
            }
            
            if self.state == .playingContent, self.configuration.skippedAdStrategy != .playNone {
                let playSeekedOverAdBreak = { (seekedTime: Double, adBreakOffset: Double) in
                    self.state = .seekingToAdStart
                    self.seek(to: adBreakOffset) { [weak self] _, error in
                        guard error == nil else {
                            os_log(.debug,log: .adIntegration, "SEEKED: Failed to seek with error: %@", error?.localizedDescription ?? "N/A")
                            return
                        }
                        self?.state = .playingSeekedOverAdBreak(seekedTime: seekedTime,
                                                                hasSeekedOnToAd: self?.adScheduler?.checkIfThereIsAnAdBreak(on: seekedTime) == true)
                        os_log(.debug,log: .adIntegration, "SEEKED: Setting state to playing seeked over adbreak with stored seek time %f", seekedTime)
                    }
                }
                switch self.configuration.skippedAdStrategy {
                case .playAll:
                    guard let adBreakOffset = self.adScheduler?.firstUnwatchedAdBreakOffset(before: event.currentTime) else {
                        return
                    }
                    os_log(.debug,log: .adIntegration, "SEEKED: Playing first unwatched ad break at: %f", adBreakOffset)
                    playSeekedOverAdBreak(event.currentTime, adBreakOffset)
                case .playLast:
                    guard let adBreakOffset = self.adScheduler?.lastUnwatchedAdBreakOffset(before: event.currentTime) else {
                        return
                    }
                    os_log(.debug,log: .adIntegration, "SEEKED: Playing last unwatched ad break at: %f", adBreakOffset)
                    playSeekedOverAdBreak(event.currentTime, adBreakOffset)
                default:
                    // No-op
                    break
                }
            }
        }
        
        playEventListener = player.addEventListener(type: PlayerEventTypes.PLAY) {  [weak self] event in
            self?.pingScheduler?.onStart(time: event.currentTime)
            os_log(.debug,log: .adIntegration, "PLAY: Received play event at: %f", event.currentTime)
        }
    }

    // Implements ServerSideAdIntegrationHandler.setSource
    func setSource(source: SourceDescription) -> Bool {
        pingScheduler = nil

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
                self.onPrePlayResponse(response: preplayResponse,
                                       sourceDescription: sourceDescription,
                                       typedSource: typedSource,
                                       ssaiConfiguration: uplynkConfig)
                let adScheduler = self.createAdScheduler(preplayResponse: preplayResponse)
                if uplynkConfig.pingFeature != .noPing {
                    os_log(.debug,log: .adIntegration, "Scheduling ping")
                    pingScheduler = PingScheduler(urlBuilder: urlBuilder,
                                                  prefix: preplayResponse.prefix,
                                                  sessionId: preplayResponse.sid, 
                                                  listener: eventListener,
                                                  controller: self.controller,
                                                  adScheduler: adScheduler)
                } else {
                    pingScheduler = nil
                }
                self.adScheduler = adScheduler
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
    
    func skipAd(ad: Ad) -> Bool {
        os_log(.debug,log: .adIntegration, "Handling skip ad")
        guard configuration.defaultSkipOffset != -1,
              let adStartTime = adScheduler?.getCurrentAdBreakStartTime(),
              adStartTime + Double(configuration.defaultSkipOffset) <= player.currentTime else {
            os_log(.debug,log: .adIntegration, "Exiting skip ad")
            return true
        }
        
        if let seekToTime = adScheduler?.getCurrentAdBreakEndTime() {
            os_log(.debug,log: .adIntegration, "Skipping the current adbreak %f", seekToTime)
            seek(to: seekToTime)
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

    private func createAdScheduler(preplayResponse: PrePlayResponseProtocol) -> AdScheduler {
        let adBreaks: [UplynkAdBreak] = (preplayResponse as? PrePlayVODResponse)?.ads.breaks ?? []
        let adHandler = AdHandler(controller: controller)
        return AdScheduler(adBreaks: adBreaks, adHandler: adHandler)
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
        self.player.source = sourceDescription
        
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
}
