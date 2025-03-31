//
//  YospaceEvents.swift
//
//  Created by Raffi on 11/06/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

enum YospaceEventsString: String {
    case sessionavailable
}

class SessionAvailableEventType: THEOplayerSDK.EventType<SessionAvailableEvent> {
    init() {
        super.init(name: YospaceEventsString.sessionavailable.rawValue)
    }
}

/** Fired when a new Yospace event occurs.*/
public class YospaceEvent: NSObject, THEOplayerSDK.EventProtocol {
    /** A textual representation of the type of the event.*/
    public let type: String
    /** The date at which the event occurred.*/
    public let date: Date

    init(type: String, date: Date) {
        self.date = date
        self.type = type
        super.init()
    }
}

/** Fired when a new Yospace session starts.*/
public class SessionAvailableEvent: YospaceEvent {
    init(date: Date) {
        super.init(type: YospaceEventsString.sessionavailable.rawValue, date: date)
    }
}

public struct YospaceEventTypes {
    /** Fired when a new Yospace session starts.*/
    public static var SESSION_AVAILABLE: THEOplayerSDK.EventType<SessionAvailableEvent> = SessionAvailableEventType()
}
