//
//  UplynkConnector.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

public class UplynkConnector {
    private let player: THEOplayer
    private var adIntegrationHandler: ServerSideAdIntegrationHandler?

    public init(player: THEOplayer) {
        self.player = player

        self.player.ads.registerServerSideIntegration(integrationId: UplynkAdIntegration.INTEGRATION_ID) { controller in
            let handler: ServerSideAdIntegrationHandler = UplynkAdIntegration(player: player, controller: controller)
            self.adIntegrationHandler = handler
            return handler
        }
    }
}
