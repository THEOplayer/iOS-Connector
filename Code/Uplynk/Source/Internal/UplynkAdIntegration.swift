//
//  UplynkAdIntegration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

class UplynkAdIntegration: THEOplayerSDK.ServerSideAdIntegrationHandler {
    static let INTEGRATION_ID: String = "uplynk"

    private let player: THEOplayerSDK.THEOplayer
    private let uplynkAPI: UplynkAPIProtocol.Type
    private let controller: THEOplayerSDK.ServerSideAdIntegrationController
    private(set) var isSettingSource: Bool = false

    private typealias UplynkAdIntegrationSource = (THEOplayerSDK.SourceDescription, THEOplayerSDK.TypedSource)

    init(uplynkAPI: UplynkAPIProtocol.Type = UplynkAPI.self,
         player: THEOplayerSDK.THEOplayer,
         controller: THEOplayerSDK.ServerSideAdIntegrationController) {
        self.uplynkAPI = uplynkAPI
        self.player = player
        self.controller = controller
    }

    // Implements ServerSideAdIntegrationHandler.setSource
    func setSource(source: SourceDescription) -> Bool {
        // copy the passed SourceDescription; we don't want to modify the original
        let sourceDescription: THEOplayerSDK.SourceDescription = source.createCopy()
        let isUplynkSSAI: (TypedSource) -> Bool = { $0.ssai as? UplynkServerSideAdIntegrationConfiguration != nil }

        guard let typedSource: THEOplayerSDK.TypedSource = sourceDescription.sources.first(where: isUplynkSSAI),
           let uplynkConfig: UplynkServerSideAdIntegrationConfiguration = typedSource.ssai as? UplynkServerSideAdIntegrationConfiguration else {
            return false
        }
        let urlBuilder = UplynkServerSideAdInjectionURLBuilder(ssaiConfiguration: uplynkConfig)
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
        let typedSource: THEOplayerSDK.TypedSource = source.1
        typedSource.src = URL(string: response.playURL)!
        if let drm = response.drm, drm.required {
            // TODO: This will need cleanup when we figure out the DRM bit.
            typedSource.drm = UplynkDRMConfiguration(keySystemConfigurations:
                    .init(fairplay: .init(certificateURL: drm.fairplayCertificateURL)))
        }

        let sourceDescription: THEOplayerSDK.SourceDescription = source.0
        self.isSettingSource = true
        self.player.source = sourceDescription
        self.isSettingSource = false
    }
}
