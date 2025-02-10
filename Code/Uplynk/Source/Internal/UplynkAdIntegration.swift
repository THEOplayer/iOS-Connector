//
//  UplynkAdIntegration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

class UplynkAdIntegration: ServerSideAdIntegrationHandler {
    
    enum State: Equatable {
        case playingContent
        case playingSeekedOverAdBreak(seekedTime: Double)
    }
    
    static let INTEGRATION_ID: String = "uplynk"

    private let player: THEOplayer
    private weak var eventListener: UplynkEventListener?
    private let uplynkAPI: UplynkAPIProtocol.Type
    private let controller: ServerSideAdIntegrationController
    private let configuration: UplynkConfiguration
    private(set) var isSettingSource: Bool = false

    private typealias UplynkAdIntegrationSource = (SourceDescription, TypedSource)

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
            guard let self else { return }
            self.pingScheduler?.onTimeUpdate(time: event.currentTime)
            self.adScheduler?.onTimeUpdate(time: event.currentTime)
            
            if case let .playingSeekedOverAdBreak(seekedTime: seekedTime) = self.state,
                self.adScheduler?.isPlayingAd == false,
                self.configuration.skippedAdStrategy != .playNone {
                
                switch self.configuration.skippedAdStrategy {
                case .playAll:
                    // Check is there is a followup ad in the list to play?
                    if let adBreakOffset = self.adScheduler?.firstUnwatchedAdBreakOffset(before: event.currentTime) {
                        // Play next ad
                        self.seek(to: adBreakOffset)
                    } else {
                        // Reset the state and seek to original seek time
                        self.state = .playingContent
                        self.seek(to: seekedTime)
                    }
                case .playLast:
                    // We have already played the last ad from on `seeked` function
                    // Reset the state and seek to original seek time
                    self.state = .playingContent
                    self.seek(to: seekedTime)
                default:
                    break
                }
            }
            
            // Seek to end time of adbreak if its already watched
            if let adBreakEndTime = self.adScheduler?.adBreakEndTimeIfPlayingAlreadyWatchedAdBreak(for: event.currentTime) {
                self.seek(to: adBreakEndTime)
            }
        }
        
        seekingEventListener = player.addEventListener(type: PlayerEventTypes.SEEKING) { [weak self] event in
            self?.pingScheduler?.onSeeking(time: event.currentTime)
        }
        
        seekedEventListener = player.addEventListener(type: PlayerEventTypes.SEEKED) { [weak self] event in
            guard let self else { return }
            
            if self.state == .playingContent {
                self.pingScheduler?.onSeeked(time: event.currentTime)
            }
            
            if self.state == .playingContent, self.configuration.skippedAdStrategy != .playNone {
                let playSeekedOverAdBreak = { (seekedTime: Double, adBreakOffset: Double) in
                    self.state = .playingSeekedOverAdBreak(seekedTime: seekedTime)
                    self.seek(to: adBreakOffset)
                }
                switch self.configuration.skippedAdStrategy {
                case .playAll:
                    guard let adBreakOffset = self.adScheduler?.firstUnwatchedAdBreakOffset(before: event.currentTime) else {
                        return
                    }
                    playSeekedOverAdBreak(event.currentTime, adBreakOffset)
                case .playLast:
                    guard let adBreakOffset = self.adScheduler?.lastUnwatchedAdBreakOffset(before: event.currentTime) else {
                        return
                    }
                    playSeekedOverAdBreak(event.currentTime, adBreakOffset)
                default:
                    // No-op
                    break
                }
            }
        }
        
        playEventListener = player.addEventListener(type: PlayerEventTypes.PLAY) {  [weak self] event in
            self?.pingScheduler?.onStart(time: event.currentTime)
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
                let source: UplynkAdIntegrationSource = (sourceDescription, typedSource)
                let preplayResponse = try await self.onPrePlayRequest(preplaySrcUrl: preplayURL, assetType: uplynkConfig.assetType)
                self.onPrePlayResponse(response: preplayResponse,
                                       source: source,
                                       ssaiConfiguration: uplynkConfig)
                let adScheduler = self.createAdScheduler(preplayResponse: preplayResponse)
                if uplynkConfig.pingFeature != .noPing {
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
        if let seekToTime = adScheduler?.getCurrentAdBreakEndTime() {
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
    }

    private func createAdScheduler(preplayResponse: PrePlayResponseProtocol) -> AdScheduler {
        let adBreaks: [UplynkAdBreak] = (preplayResponse as? PrePlayVODResponse)?.ads.breaks ?? []
        let adHandler = AdHandler(controller: controller, defaultSkipOffset: configuration.defaultSkipOffset)
        return AdScheduler(adBreaks: adBreaks, adHandler: adHandler)
    }
    
    private func onPrePlayRequest(preplaySrcUrl: String, assetType: UplynkSSAIConfiguration.AssetType) async throws -> PrePlayResponseProtocol {
        switch assetType {
        case .asset:
            return try await uplynkAPI.requestVOD(preplaySrcURL: preplaySrcUrl)
        case .channel:
            return try await uplynkAPI.requestLive(preplaySrcURL: preplaySrcUrl)
        }
    }
    
    private func onPrePlayResponse(response: PrePlayResponseProtocol,
                                   source: UplynkAdIntegrationSource,
                                   ssaiConfiguration: UplynkSSAIConfiguration) {
        let typedSource: TypedSource = source.1
        let playURL = if ssaiConfiguration.playbackURLParametersString.isEmpty == false {
            "\(response.playURL)?\(ssaiConfiguration.playbackURLParametersString)"
        } else {
            response.playURL
        }
        typedSource.src = URL(string: playURL)!
        if let drm = response.drm, drm.required {
            // TODO: This will need cleanup when we figure out the DRM bit.
            typedSource.drm = FairPlayDRMConfiguration(customIntegrationId: UplynkAdIntegration.INTEGRATION_ID, licenseAcquisitionURL: "", certificateURL: drm.fairplayCertificateURL)
        }
        let sourceDescription: SourceDescription = source.0
        self.player.source = sourceDescription
        
        if let liveResponse = response as? PrePlayLiveResponse {
            eventListener?.onPreplayLiveResponse(liveResponse)
        } else if let vodResponse = response as? PrePlayVODResponse {
            eventListener?.onPreplayVODResponse(vodResponse)
        }
    }
    
    private func seek(to offset: Double) {
        player.currentTime = offset
    }
}
