//
//  YospaceConnector.swift
//
//  Created by Raffi on 29/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

public class YospaceConnector {
	let yospaceManager: YospaceManager

	public init(player: THEOplayer) {
        self.yospaceManager = YospaceManager(player: player)
    }

    public func setupYospaceSession(sourceDescription: SourceDescription, sessionProperties: YOSessionProperties? = nil) {
        self.yospaceManager.createYospaceSource(sourceDescription: sourceDescription, sessionProperties: sessionProperties)
    }
}
