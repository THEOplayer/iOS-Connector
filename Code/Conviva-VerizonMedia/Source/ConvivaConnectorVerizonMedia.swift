//
//  File.swift
//  
//
//  Created by Damiaan Dufaux on 12/10/2022.
//

import ConvivaSDK
import THEOplayerConnectorConviva
import THEOplayerSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public struct ConvivaConnectorVerizonMedia: ConvivaEndpointContainer {
    let base: ConvivaConnector
    let verizonMediaEventHandler: VerizonAdEventForwarder

    public init(base: ConvivaConnector) {
        self.base = base
        verizonMediaEventHandler = VerizonAdEventForwarder(
            player: base.player,
            eventProcessor: VerizonAdEventConvivaReporter(
                videoAnalytics: base.videoAnalytics,
                adAnalytics: base.adAnalytics
            )
        )
    }
    
    public init?(configuration: THEOplayerConnectorConviva.ConvivaConfiguration, player: THEOplayer) {
        guard let base = ConvivaConnector(configuration: configuration, player: player) else {
            return nil
        }
        self.init(base: base)
    }
    
    public var conviva: ConvivaEndpoints {
        base.conviva
    }
    
    public var player: THEOplayer { base.player }
}
