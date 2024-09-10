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
    private(set) var isSettingSource: Bool = false

    private typealias UplynkAdIntegrationSource = (THEOplayerSDK.SourceDescription, THEOplayerSDK.TypedSource)

    init(player: THEOplayerSDK.THEOplayer) {
        self.player = player
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

        let preplayUrl: String = UplynkServerSideAdIntegrationConfigurationConverter.buildPreplayUrl(ssaiDescription: uplynkConfig)
        UplynkApi.requestPreplay(srcURL: preplayUrl) { preplayResponse in
            guard let response: PreplayResponse = preplayResponse else { return }
            let source: UplynkAdIntegrationSource = (sourceDescription, typedSource)
            self.onPreplayResponse(response: response, source: source)
        }

        return true
    }

    private func onPreplayResponse(response: PreplayResponse, source: UplynkAdIntegrationSource) {
        let typedSource: THEOplayerSDK.TypedSource = source.1
        typedSource.src = URL(string: response.playURL)!
        let sourceDescription: THEOplayerSDK.SourceDescription = source.0
        self.isSettingSource = true
        self.player.source = sourceDescription
        self.isSettingSource = false
    }
}
