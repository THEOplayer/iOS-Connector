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

extension YospaceConnector: THEOplayerSDK.EventDispatcherProtocol {
    public func addEventListener<E>(type: THEOplayerSDK.EventType<E>, listener: @escaping (E) -> ()) -> THEOplayerSDK.EventListener where E : THEOplayerSDK.EventProtocol {
        return self.yospaceManager.eventDispatcher.addEventListener(type: type, listener: listener)
    }

    public func removeEventListener<E>(type: THEOplayerSDK.EventType<E>, listener: THEOplayerSDK.EventListener) where E : THEOplayerSDK.EventProtocol {
        self.yospaceManager.eventDispatcher.removeEventListener(type: type, listener: listener)
    }
}
