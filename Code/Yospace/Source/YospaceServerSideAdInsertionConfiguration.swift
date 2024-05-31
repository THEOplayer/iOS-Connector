//
//  YospaceServerSideAdInsertionConfiguration.swift
//
//  Created by Raffi on 29/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

public enum YospaceStreamType {
    case live
    case livepause
    case vod
}

public class YospaceServerSideAdInsertionConfiguration: THEOplayerSDK.ServerSideAdInsertionConfiguration {
    public var integration: THEOplayerSDK.SSAIIntegrationId = .YospaceSSAIIntegrationID
    var streamType: YospaceStreamType

    init(streamType: YospaceStreamType) {
        self.streamType = streamType
    }
}
