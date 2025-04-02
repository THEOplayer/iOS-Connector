//
//  EventDispatcher.swift
//
//  Created by Raffi on 11/06/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

class EventDispatcher: THEOplayerSDK.EventDispatcherProtocol {
    private var eventListeners: [String: [EventListenerWrapperInterface]] = [:]

    func addEventListener<E>(type: THEOplayerSDK.EventType<E>, listener: @escaping (E) -> ()) -> THEOplayerSDK.EventListener where E : THEOplayerSDK.EventProtocol {
        let eventListener: EventListenerWrapper<E> = .init(listener: listener)
        let listeners: [EventListenerWrapperInterface] = self.eventListeners[type.name] ?? []
        self.eventListeners[type.name] = listeners + [eventListener]
        return eventListener
    }

    func removeEventListener<E>(type: THEOplayerSDK.EventType<E>, listener: THEOplayerSDK.EventListener) where E : THEOplayerSDK.EventProtocol {
        guard let eventListener = listener as? EventListenerWrapperInterface else { return }
        self.eventListeners[type.name]?.removeAll { $0 === eventListener }
    }

    func dispatchEvent(event: THEOplayerSDK.EventProtocol) {
        guard let listeners: [EventListenerWrapperInterface] = self.eventListeners[event.type] else { return }
        for listener in listeners {
            listener.invoke(event: event)
        }
    }

    func clear() {
        self.eventListeners.removeAll()
    }
}

class EventListenerWrapper<E: THEOplayerSDK.EventProtocol>: EventListenerWrapperInterface, THEOplayerSDK.EventListener {
    private let listener: (E) -> ()

    init(listener: @escaping (E) -> ()) {
        self.listener = listener
    }

    func invoke(event: THEOplayerSDK.EventProtocol) {
        self.listener(event as! E)
    }
}

protocol EventListenerWrapperInterface: AnyObject {
    func invoke(event: THEOplayerSDK.EventProtocol)
}
