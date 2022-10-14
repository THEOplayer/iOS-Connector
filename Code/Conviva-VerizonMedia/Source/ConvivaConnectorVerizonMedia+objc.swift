//
//  ConvivaConnectorVerizonMedia+objc.swift
//  
//
//  Created by Damiaan Dufaux on 17/10/2022.
//

import class Foundation.NSObject
import THEOplayerConnectorConviva
import THEOplayerSDK

@objc class THEOplayerConvivaConnectorVerizonMedia: NSObject {
    let internalConnector: THEOplayerConvivaConnectorVerizonMedia
    
    public init(conviva: ConvivaEndpoints, player: THEOplayer) {
        internalConnector = .init(conviva: conviva, player: player)
    }
    
    @objc public convenience init?(configuration: THEOplayerConvivaConfiguration, player: THEOplayer) {
        guard let endpoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endpoints, player: player)
    }
    
    @objc
    public func report(viewerID: String) {
        internalConnector.report(viewerID: viewerID)
    }
    
    @objc
    public func report(assetName: String) {
        internalConnector.report(assetName: assetName)
    }
}
