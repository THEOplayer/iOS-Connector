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

    init(uplynkAPI: UplynkAPIProtocol.Type = UplynkAPI.self,
         player: THEOplayer,
         controller: ServerSideAdIntegrationController,
         eventListener: UplynkEventListener? = nil) {
        self.eventListener = eventListener
        self.uplynkAPI = uplynkAPI
        self.player = player
        self.controller = controller
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
                let source: UplynkAdIntegrationSource = (sourceDescription, typedSource)
                let preplayResponse = try await self.onPrePlayRequest(preplaySrcUrl: preplayURL, assetType: uplynkConfig.assetType)
                self.onPrePlayResponse(response: preplayResponse, source: source)
            } catch {
                let uplynkError = UplynkError(
                    url: preplayURL,
                    description: error.localizedDescription,
                    code: .UPLYNK_ERROR_CODE_PREPLAY_REQUEST_FAILED)
                eventListener?.onError(uplynkError: uplynkError)
                controller.error(error: uplynkError)
            }
        }
        
        return true
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
            eventListener?.onResponse(preplayLive: liveResponse)
        } else if let vodResponse = response as? PrePlayVODResponse {
            eventListener?.onResponse(preplayVOD: vodResponse)
        }
    }
}
