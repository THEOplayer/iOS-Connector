//
//  PingScheduler.swift
//
//
//  Created by Raveendran, Aravind on 30/1/2025.
//

import Foundation
import THEOplayerSDK

final class PingScheduler {

    private let uplynkApiType: UplynkAPIProtocol.Type
    private let urlBuilder: UplynkSSAIURLBuilder
    private let prefix: String
    private let sessionId: String
    private let controller: ServerSideAdIntegrationController

    private var nextRequestTime: Double?
    private var seekStart: Double?
    private weak var listener: UplynkEventListener?
    private var adScheduler: AdScheduler
    private static let STOP_PING: Double = -1

    init(
        urlBuilder: UplynkSSAIURLBuilder,
        prefix: String,
        sessionId: String,
        listener: UplynkEventListener?,
        controller: ServerSideAdIntegrationController,
        adScheduler: AdScheduler,
        uplynkApiType: UplynkAPIProtocol.Type = UplynkAPI.self
    ) {
        self.urlBuilder = urlBuilder
        self.prefix = prefix
        self.sessionId = sessionId
        self.listener = listener
        self.controller = controller
        self.adScheduler = adScheduler
        self.uplynkApiType = uplynkApiType
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
            guard let self else {
                return
            }
            do {
                let pingResponse = try await self.uplynkApiType.requestPing(url: url)
                self.nextRequestTime = pingResponse.nextTime
                self.listener?.onPingResponse(pingResponse)
                // TODO: Add Ad's to Ad scheduler
            } catch {
                let uplynkError = UplynkError(
                    url: url,
                    description: error.localizedDescription,
                    code: .UPLYNK_ERROR_CODE_PING_REQUEST_FAILED)
                self.listener?.onError(uplynkError)
                self.controller.error(error: uplynkError)
            }
        }
    }
}
