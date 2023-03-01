//
//  NielsenConnector.swift
//  
//
//  Created by Damiaan Dufaux on 28/02/2023.
//

import NielsenAppApi
import THEOplayerSDK

/// Connects to a THEOplayer instance and reports its events to Nielsen.
public struct NielsenConnector {
    public let nielsen: NielsenAppApi
    public let player: THEOplayer
    
    
    public init?(configuration: Any, player: THEOplayer) {
        guard let nielsen = NielsenAppApi(appInfo: configuration, delegate: nil) else { return nil }
        self.init(nielsen: nielsen, player: player)
    }

    public init(nielsen: NielsenAppApi, player: THEOplayer) {
        self.nielsen = nielsen
        self.player = player
        
        
        
        
        // Report fore- and background changes
        
        // Report play pause etc
        
        // Report ad events
    }
}
