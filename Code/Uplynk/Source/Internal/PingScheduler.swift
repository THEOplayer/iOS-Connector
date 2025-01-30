//
//  PingScheduler.swift
//
//
//  Created by Raveendran, Aravind on 30/1/2025.
//

import Foundation

// TODO: Move it to a separate file
protocol UplynkEventDispatcher: AnyObject {
    func dispatchPingEvent(_ response: PingResponse)
}

final class PingScheduler {
    private let uplynkApiType: UplynkAPIProtocol.Type
    private let urlBuilder: UplynkSSAIURLBuilder
    private let prefix: String
    private let sessionId: String

    private var nextRequestTime: Double?
    private var seekStart: Double?
    weak var eventDispatcher: UplynkEventDispatcher?
    
    private static let STOP_PING: Double = -1

    init(uplynkApiType: UplynkAPIProtocol.Type = UplynkAPI.self,
         urlBuilder: UplynkSSAIURLBuilder,
         prefix: String,
         sessionId: String) {
        self.uplynkApiType = uplynkApiType
        self.urlBuilder = urlBuilder
        self.prefix = prefix
        self.sessionId = sessionId
    }
    
    func onTimeUpdate(time: Double) {
        guard let nextRequestTime,
              nextRequestTime != PingScheduler.STOP_PING,
              time > nextRequestTime
        else {
            return
        }
        let url = urlBuilder.buildPingURL(prefix: prefix,
                                          sessionID: sessionId,
                                          currentTimeSeconds: Int(time))
        performPing(url: url)
    }
    
    func onStart(time: Double) {
        let url = urlBuilder.buildStartPingURL(prefix: prefix,
                                               sessionID: sessionId,
                                               currentTimeSeconds: Int(time))
        performPing(url: url)
    }
    
    func onSeeking(time: Double) {
        guard seekStart == nil, nextRequestTime != PingScheduler.STOP_PING else { return }
        seekStart = time
    }
    
    func onSeeked(time: Double) {
        guard let seekStart, nextRequestTime != PingScheduler.STOP_PING else { return }
        let url = urlBuilder.buildSeekedPingURL(prefix: prefix,
                                                sessionID: sessionId,
                                                currentTimeSeconds: Int(time),
                                                seekStartTimeSeconds: Int(seekStart))
        performPing(url: url)

        self.seekStart = nil
    }
    
    private func performPing(url: String) {
        Task { @MainActor [weak self] in
            guard let self,
                  let pingResponse = await self.uplynkApiType.requestPing(url: url)
            else {
                return
            }
            
            self.nextRequestTime = pingResponse.nextTime
            self.eventDispatcher?.dispatchPingEvent(pingResponse)
            // TODO: Aravind: Add Ad's to Ad scheduler
        }
    }
}
