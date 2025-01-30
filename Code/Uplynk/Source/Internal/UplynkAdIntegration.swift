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
    private let uplynkAPI: UplynkAPIProtocol.Type
    private let controller: ServerSideAdIntegrationController
    private(set) var isSettingSource: Bool = false

    private typealias UplynkAdIntegrationSource = (SourceDescription, TypedSource)

    init(uplynkAPI: UplynkAPIProtocol.Type = UplynkAPI.self,
         player: THEOplayer,
         controller: ServerSideAdIntegrationController) {
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
            let requestMethod = switch uplynkConfig.assetType {
            case .asset:
                self.uplynkAPI.requestVOD(preplaySrcURL:)
            case .channel:
                self.uplynkAPI.requestLive(preplaySrcURL:)
            }
            guard let preplayResponse = await requestMethod(preplayURL) as? PrePlayResponseProtocol else {
                // TODO: Handle as an error or log?
                return
            }
            let source: UplynkAdIntegrationSource = (sourceDescription, typedSource)
            self.onPreplayResponse(response: preplayResponse, source: source)
        }
        return true
    }

    
    private func onPreplayResponse(response: PrePlayResponseProtocol, source: UplynkAdIntegrationSource) {
        let typedSource: TypedSource = source.1
        typedSource.src = URL(string: response.playURL)!
        if let drm = response.drm, drm.required {
            // TODO: This will need cleanup when we figure out the DRM bit.
            typedSource.drm = UplynkDRMConfiguration(keySystemConfigurations:
                    .init(fairplay: .init(certificateURL: drm.fairplayCertificateURL)))
        }

        let sourceDescription: SourceDescription = source.0
        self.player.source = sourceDescription
        self.isSettingSource = false
    }
}
