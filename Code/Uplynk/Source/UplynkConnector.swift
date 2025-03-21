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
    private weak var eventListener: UplynkEventListener?
    public init(player: THEOplayer, configuration: UplynkConfiguration = .init(), eventListener: UplynkEventListener? = nil) {
        self.player = player
        self.eventListener = eventListener
        self.player.ads.registerServerSideIntegration(integrationId: UplynkAdIntegration.INTEGRATION_ID) { controller in
            let handler: ServerSideAdIntegrationHandler = UplynkAdIntegration(
                player: player,
                controller: controller,
                configuration: configuration,
                eventListener: eventListener
            )
            self.adIntegrationHandler = handler
            return handler
        }
    }
}
