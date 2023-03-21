//
//  NielsenConnector.swift
//  
//
//  Created by Damiaan Dufaux on 28/02/2023.
//

#if os(iOS)
import NielsenAppApi
#elseif os(tvOS)
import NielsenTVAppApi
#endif
import THEOplayerSDK

/// Connects to a THEOplayer instance and reports its events to Nielsen.
public struct NielsenConnector {
    public let nielsen: NielsenAppApi
    public let player: THEOplayer
    
    let basicPlaybackEventHandler: BasicEventForwarder
    let adEventHandler: AdEventForwarder

    public init?(configuration: Any, player: THEOplayer) {
        guard let nielsen = NielsenAppApi(appInfo: configuration, delegate: nil) else { return nil }
        self.init(nielsen: nielsen, player: player)
    }

    public init(nielsen: NielsenAppApi, player: THEOplayer) {
        self.nielsen = nielsen
        self.player = player
        
        // Report play, pause, etc.
        basicPlaybackEventHandler = BasicEventForwarder(
            player: player,
            eventProcessor: BasicEventReporter(nielsen: nielsen)
        )
        
        // Report ad events
        adEventHandler = AdEventForwarder(
            player: player,
            eventProcessor: AdEventReporter(nielsen: nielsen)
        )
    }
}
