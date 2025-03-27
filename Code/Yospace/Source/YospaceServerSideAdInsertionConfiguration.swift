//
//  YospaceServerSideAdInsertionConfiguration.swift
//
//  Created by Raffi on 29/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

/**
 The type of the Yospace stream, represented by a value from the following list:
    - live: The stream is a live stream.
    - livepause: The stream is a live stream with a large DVR window.
    - vod: The stream is a video-on-demand stream.
 */
public enum YospaceStreamType: Int {
    case live
    case livepause
    case vod
}

/** Represents a configuration for server-side ad insertion with the Yospace integration.*/
public class YospaceServerSideAdInsertionConfiguration: NSObject, THEOplayerSDK.CustomServerSideAdInsertionConfiguration {
    public let integration: THEOplayerSDK.SSAIIntegrationId = .CustomSSAIIntegrationID
    public let customIntegration: String = "yospace"

    /** The type of the requested stream.*/
    public let streamType: YospaceStreamType
    /** The properties that will be used set to customize the Yospace session. */
    public let sessionProperties: YOSessionProperties?

    public init(streamType: YospaceStreamType, sessionProperties: YOSessionProperties? = nil) {
        self.streamType = streamType
        self.sessionProperties = sessionProperties
        super.init()
    }
}
