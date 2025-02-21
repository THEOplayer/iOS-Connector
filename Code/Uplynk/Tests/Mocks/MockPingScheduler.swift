//
//  MockPingScheduler.swift
//
//
//  Created by Raveendran, Aravind on 17/2/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

final class MockPingScheduler: PingSchedulerProtocol {
    
    enum Event: Equatable {
        case onTimeUpdate(Double)
        case onStart(Double)
        case onSeeking(Double)
        case onSeeked(Double)
    }
    private(set) var events: [Event] = []
    
    func onTimeUpdate(time: Double) {
        events.append(.onTimeUpdate(time))
    }
    
    func onStart(time: Double) {
        events.append(.onStart(time))
    }
    
    func onSeeking(time: Double) {
        events.append(.onSeeking(time))
    }
    
    func onSeeked(time: Double) {
        events.append(.onSeeked(time))
    }
}
