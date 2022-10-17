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
    let internalConnector: ConvivaConnectorVerizonMedia
    
    init(conviva: ConvivaConnectorVerizonMedia) {
        internalConnector = conviva
    }
    
    @objc public convenience init?(configuration: THEOplayerConvivaConfiguration, player: THEOplayer) {
        guard let endpoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        let base = ConvivaConnector(conviva: endpoints, player: player)
        self.init(conviva: ConvivaConnectorVerizonMedia(base: base))
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
