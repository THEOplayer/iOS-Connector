//
//  MockUplynkSSAIURLBuilder.swift
//
//
//  Created by Raveendran, Aravind on 31/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

final class MockUplynkSSAIURLBuilder: UplynkSSAIURLBuilder {
    
    enum Event: Equatable {
        case buildPreplayVODURL
        case buildPreplayLiveURL
        case buildPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int)
        case buildStartPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int)
        case buildSeekedPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int, seekStartTimeSeconds: Int)
    }
    
    private(set) var events: [Event] = []
    
    override func buildPreplayVODURL() -> String {
        events.append(.buildPreplayVODURL)
        return super.buildPreplayVODURL()
    }
    
    override func buildPreplayLiveURL() -> String {
        events.append(.buildPreplayLiveURL)
        return super.buildPreplayLiveURL()
    }
    
    override func buildPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int) -> String {
        events.append(.buildPingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds))
        return super.buildPingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds)
    }
    
    override func buildStartPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int) -> String {
        events.append(.buildStartPingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds))
        return super.buildStartPingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds)
    }
    
    override func buildSeekedPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int, seekStartTimeSeconds: Int) -> String {
        events.append(.buildSeekedPingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds, seekStartTimeSeconds: seekStartTimeSeconds))
        return super.buildSeekedPingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds, seekStartTimeSeconds: seekStartTimeSeconds)
    }
}
