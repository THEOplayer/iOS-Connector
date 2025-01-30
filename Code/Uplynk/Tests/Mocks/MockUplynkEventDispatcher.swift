//
//  MockUplynkEventDispatcher.swift
//
//
//  Created by Raveendran, Aravind on 31/1/2025.
//

import Combine
import Foundation
@testable import THEOplayerConnectorUplynk

final class MockUplynkEventDispatcher: UplynkEventDispatcher {
    enum Event: Equatable {
        case dispatchPingEvent(PingResponse)
    }
    
    private(set) var events: [Event] = []
    let eventSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        eventSubject
            .sink { [weak self] event in
                self?.events.append(event)
            }
            .store(in: &cancellables)
    }

    func dispatchPingEvent(_ response: PingResponse) {
        eventSubject.send(.dispatchPingEvent(response))
    }
}
