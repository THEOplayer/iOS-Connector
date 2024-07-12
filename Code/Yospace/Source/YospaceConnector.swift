//
//  YospaceConnector.swift
//
//  Created by Raffi on 29/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

@objc(THEOplayerYospaceConnector)
public class YospaceConnector: NSObject {
	let yospaceManager: YospaceManager

    /**
     Initialises a Yospace connector.

     - Parameters:
        - player: The THEOplayer instance that the Yospace connector will be registered to.
     */
    @objc public init(player: THEOplayer) {
        self.yospaceManager = YospaceManager(player: player)
        super.init()
    }

    /**
     Creates the Yospace session and sets the Yospace source from the session to the player.

     - Parameters:
        - sourceDescription: the source that will be used to create the Yospace session.
     */
    @objc public func setupYospaceSession(sourceDescription: SourceDescription) {
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

@available(swift, obsoleted: 1.0)
extension YospaceConnector: THEOplayerSDK.EventDispatcherProtocol_Objc {
    @available(swift, obsoleted: 1.0)
    @objc public func addEventListener_Objc(type: String, listener: @escaping (THEOplayerSDK.EventProtocol) -> ()) -> THEOplayerSDK.EventListener {
        switch type {
        case YospaceEventTypes.SESSION_AVAILABLE.name:
            return self.addEventListener(type: YospaceEventTypes.SESSION_AVAILABLE, listener: listener)
        default:
            fatalError("The EventType \(type) is NOT compatible with the current EventDispatcher, please consider using the `YospaceEventTypes`")
        }
    }
    @available(swift, obsoleted: 1.0)
    @objc public func removeEventListener_Objc(type: String, listener: THEOplayerSDK.EventListener) {
        switch type {
        case YospaceEventTypes.SESSION_AVAILABLE.name:
            return self.removeEventListener(type: YospaceEventTypes.SESSION_AVAILABLE, listener: listener)
        default:
            fatalError("The EventType \(type) is NOT compatible with the current EventDispatcher, please consider using the `YospaceEventTypes`")
        }
    }
}
