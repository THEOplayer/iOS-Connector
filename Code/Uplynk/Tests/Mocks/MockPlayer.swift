//
//  MockPlayer.swift
//  
//
//  Created by Raveendran, Aravind on 14/2/2025.
//

import Foundation
import THEOplayerSDK
@testable import THEOplayerConnectorUplynk

final class MockEventListener: EventListener {}

final class MockPlayer: Player {
    enum Event: Equatable {
        case setSource([TypedSource]?)
        case addEventListener(name: String)
        case setCurrentTime(Double)
    }
    private(set) var events: [Event] = []
    
    var currentTime: Double = 0.0
    var source: SourceDescription? {
        didSet {
            events.append(.setSource(source?.sources))
        }
    }
    
    var timeUpdateListener: ((TimeUpdateEvent) -> ())?
    var seekingListener: ((SeekingEvent) -> ())?
    var seekedListener: ((SeekedEvent) -> ())?
    func addEventListener<E>(type: EventType<E>, listener: @escaping (E) -> ()) -> EventListener where E : EventProtocol {
        events.append(.addEventListener(name: type.name))
        if type.name == PlayerEventTypes.TIME_UPDATE.name, let seekedListener = listener as? (TimeUpdateEvent) -> () {
            self.timeUpdateListener = seekedListener
        } else if type.name == PlayerEventTypes.SEEKING.name, let seekedListener = listener as? (SeekingEvent) -> () {
            self.seekingListener = seekedListener
        } else if type.name == PlayerEventTypes.SEEKED.name, let seekedListener = listener as? (SeekedEvent) -> () {
            self.seekedListener = seekedListener
        }
        return MockEventListener()
    }
    
    func setCurrentTime(_ newValue: Double, completionHandler: ((Any?, (Error)?) -> Void)?) {
        currentTime = newValue
        events.append(.setCurrentTime(newValue))
        completionHandler?(nil, nil)
    }
}
