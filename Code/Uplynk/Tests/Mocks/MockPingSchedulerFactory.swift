//
//  MockPingSchedulerFactory.swift
//
//
//  Created by Raveendran, Aravind on 17/2/2025.
//

import Foundation
import THEOplayerSDK
@testable import THEOplayerConnectorUplynk

final class MockPingSchedulerFactory: PingSchedulerFactory {
    static var mockPingScheduler: MockPingScheduler!

    static func make(urlBuilder: UplynkSSAIURLBuilder,
                     prefix: String,
                     sessionId: String,
                     listener: UplynkEventListener?,
                     controller: ServerSideAdIntegrationController,
                     adScheduler: AdSchedulerProtocol,
                     uplynkApiType: UplynkAPIProtocol.Type) -> PingSchedulerProtocol {
        mockPingScheduler
    }
    
    static func reset() {
        mockPingScheduler = nil
    }
}
