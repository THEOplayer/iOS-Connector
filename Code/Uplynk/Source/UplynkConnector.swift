//
//  UplynkConnector.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

public class UplynkConnector {
    private let player: THEOplayerSDK.THEOplayer
    private var adIntegrationHandler: THEOplayerSDK.ServerSideAdIntegrationHandler?

    public init(player: THEOplayerSDK.THEOplayer) {
        self.player = player

        self.player.ads.registerServerSideIntegration(integrationId: UplynkAdIntegration.INTEGRATION_ID) { controller in
            let handler: THEOplayerSDK.ServerSideAdIntegrationHandler = UplynkAdIntegration(player: player)
            self.adIntegrationHandler = handler
            return handler
        }
    }
}
