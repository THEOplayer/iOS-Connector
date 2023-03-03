//
//  DispatchObserver.swift
//  
//
//  Created by Damiaan Dufaux on 21/09/2022.
//

import THEOplayerSDK

/// A place to safely store event listeners. Once instances of this object get released, listeners stored inside it are also removed
public class DispatchObserver {
    let dispatcher: EventDispatcherProtocol
    let eventListeners: [RemovableEventListenerProtocol]
    
    public init(dispatcher: EventDispatcherProtocol, eventListeners: [RemovableEventListenerProtocol]) {
        self.dispatcher = dispatcher
        self.eventListeners = eventListeners
    }
        
    deinit {
        for listener in eventListeners {
            dispatcher.remove(eventListener: listener)
        }
    }
}
