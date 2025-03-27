//
//  YospaceConnector.swift
//
//  Created by Raffi on 29/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

public class YospaceConnector: NSObject {
	let yospaceManager: YospaceManager

    /**
     Initialises a Yospace connector.

     - Parameters:
        - player: The THEOplayer instance that the Yospace connector will be registered to.
     */
    public init(player: THEOplayer) {
        self.yospaceManager = YospaceManager(player: player)
        super.init()
    }

    /**
     Creates the Yospace session and sets the Yospace source from the session to the player.

     - Parameters:
        - sourceDescription: the source that will be used to create the Yospace session.
     */
    public func setupYospaceSession(sourceDescription: SourceDescription) {
        self.yospaceManager.didSetSourceFromConnector = true
        _ = self.yospaceManager.createYospaceSource(sourceDescription: sourceDescription)
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
