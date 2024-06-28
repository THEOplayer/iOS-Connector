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
@objc(THEOplayerYospaceEvent)
public class YospaceEvent: NSObject, THEOplayerSDK.EventProtocol {
    /** A textual representation of the type of the event.*/
    @objc public let type: String
    /** The date at which the event occurred.*/
    @objc public let date: Date

    init(type: String, date: Date) {
        self.date = date
        self.type = type
        super.init()
    }
}

/** Fired when a new Yospace session starts.*/
@objc(THEOplayerSessionAvailableEvent)
public class SessionAvailableEvent: YospaceEvent {
    init(date: Date) {
        super.init(type: YospaceEventsString.sessionavailable.rawValue, date: date)
    }
}

public struct YospaceEventTypes {
    /** Fired when a new Yospace session starts.*/
    public static var SESSION_AVAILABLE: THEOplayerSDK.EventType<SessionAvailableEvent> = SessionAvailableEventType()
}

@available(swift, obsoleted: 1.0)
@objc(THEOplayerYospaceEventTypes)
public class YospaceEventTypes_Objc: NSObject {
    /** Fired when a new Yospace session starts.*/
    @objc public static let sessionavailable = YospaceEventsString.sessionavailable.rawValue
}
