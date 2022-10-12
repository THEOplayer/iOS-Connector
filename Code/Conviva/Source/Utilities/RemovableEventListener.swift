//
//  RemovableEventListener.swift
//  
//
//  Created by Damiaan Dufaux on 01/09/2022.
//

import THEOplayerSDK

protocol RemovableEventListenerProtocol {
    func remove(from dispatcher: EventDispatcherProtocol)
}

struct RemovableEventListener<Event: EventProtocol>: RemovableEventListenerProtocol {
    let type: EventType<Event>
    let listener: EventListener
    
    func remove(from dispatcher: EventDispatcherProtocol) {
        dispatcher.removeEventListener(type: type, listener: listener)
    }
}

extension EventDispatcherProtocol {
    func addRemovableEventListener<Event: EventProtocol>(type: EventType<Event>, listener: @escaping (Event)->Void) -> RemovableEventListener<Event> {
        RemovableEventListener(
            type: type,
            listener: addEventListener(type: type, listener: listener)
        )
    }
    
    func remove(eventListener: RemovableEventListenerProtocol) {
        eventListener.remove(from: self)
    }
}
