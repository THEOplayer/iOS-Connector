//
//  YospaceServerSideAdInsertionConfiguration.swift
//
//  Created by Raffi on 29/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

@objc(THEOplayerYospaceStreamType)
public enum YospaceStreamType: Int {
    case live
    case livepause
    case vod
}

@objc(THEOplayerYospaceServerSideAdInsertionConfiguration)
public class YospaceServerSideAdInsertionConfiguration: NSObject, THEOplayerSDK.ServerSideAdInsertionConfiguration {
    @objc public var integration: THEOplayerSDK.SSAIIntegrationId = .YospaceSSAIIntegrationID
    var streamType: YospaceStreamType

    init(streamType: YospaceStreamType) {
        self.streamType = streamType
        super.init()
    }
}
