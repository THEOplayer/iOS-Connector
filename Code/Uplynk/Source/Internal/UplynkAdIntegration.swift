//
//  UplynkAdIntegration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

class UplynkAdIntegration: ServerSideAdIntegrationHandler {
    static let INTEGRATION_ID: String = "uplynk"

    private let player: THEOplayer
    private weak var eventListener: UplynkEventListener?
    private let uplynkAPI: UplynkAPIProtocol.Type
    private let controller: ServerSideAdIntegrationController
    private(set) var isSettingSource: Bool = false

    private typealias UplynkAdIntegrationSource = (SourceDescription, TypedSource)

    private var pingScheduler: PingScheduler?

    private var adScheduler: AdScheduler?
    
    // MARK: Private event listener's
    
    private var timeUpdateEventListener: EventListener?
    private var seekingEventListener: EventListener?
    private var seekedEventListener: EventListener?
    private var playEventListener: EventListener?

    init(uplynkAPI: UplynkAPIProtocol.Type = UplynkAPI.self,
         player: THEOplayer,
         controller: ServerSideAdIntegrationController,
         eventListener: UplynkEventListener? = nil) {
        self.eventListener = eventListener
        self.uplynkAPI = uplynkAPI
        self.player = player
        self.controller = controller
        
        // Setup event listner's to schedule ping
        timeUpdateEventListener = player.addEventListener(type: PlayerEventTypes.TIME_UPDATE) { [weak self] event in
            self?.pingScheduler?.onTimeUpdate(time: event.currentTime)
            self?.adScheduler?.onTimeUpdate(time: event.currentTime)
        }
        
        seekingEventListener = player.addEventListener(type: PlayerEventTypes.SEEKING) { [weak self] event in
            self?.pingScheduler?.onSeeking(time: event.currentTime)
        }
        
        seekedEventListener = player.addEventListener(type: PlayerEventTypes.SEEKED) { [weak self] event in
            self?.pingScheduler?.onSeeked(time: event.currentTime)
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
                self.onPrePlayResponse(response: preplayResponse, source: source)
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
        let adHandler = AdHandler(controller: controller)
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
    
    private func onPrePlayResponse(response: PrePlayResponseProtocol, source: UplynkAdIntegrationSource) {
        let typedSource: TypedSource = source.1
        typedSource.src = URL(string: response.playURL)!
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
}
