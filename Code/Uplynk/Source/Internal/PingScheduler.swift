//
//  PingScheduler.swift
//
//
//  Created by Raveendran, Aravind on 30/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation
import THEOplayerSDK

protocol PingSchedulerFactory {
    static func make(
        urlBuilder: UplynkSSAIURLBuilder,
        prefix: String,
        sessionId: String,
        listener: UplynkEventListener?,
        controller: ServerSideAdIntegrationController,
        adScheduler: AdSchedulerProtocol,
        uplynkApiType: UplynkAPIProtocol.Type
    ) -> PingSchedulerProtocol
}

protocol PingSchedulerProtocol {
    func onTimeUpdate(time: Double)
    func onStart(time: Double)
    func onSeeking(time: Double)
    func onSeeked(time: Double)
}

final class PingScheduler: PingSchedulerProtocol, PingSchedulerFactory {

    private let uplynkApiType: UplynkAPIProtocol.Type
    private let urlBuilder: UplynkSSAIURLBuilder
    private let prefix: String
    private let sessionId: String
    private let controller: ServerSideAdIntegrationController

    private var nextRequestTime: Double?
    private var seekStart: Double?
    private weak var listener: UplynkEventListener?
    private var adScheduler: AdSchedulerProtocol
    private static let STOP_PING: Double = -1

    static func make(
        urlBuilder: UplynkSSAIURLBuilder,
        prefix: String,
        sessionId: String,
        listener: UplynkEventListener?,
        controller: ServerSideAdIntegrationController,
        adScheduler: AdSchedulerProtocol,
        uplynkApiType: UplynkAPIProtocol.Type
    ) -> PingSchedulerProtocol {
        Self.init(urlBuilder: urlBuilder,
                  prefix: prefix,
                  sessionId: sessionId,
                  listener: listener,
                  controller: controller,
                  adScheduler: adScheduler,
                  uplynkApiType: uplynkApiType)
    }
    
    init(
        urlBuilder: UplynkSSAIURLBuilder,
        prefix: String,
        sessionId: String,
        listener: UplynkEventListener?,
        controller: ServerSideAdIntegrationController,
        adScheduler: AdSchedulerProtocol,
        uplynkApiType: UplynkAPIProtocol.Type
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
              nextRequestTime != Self.STOP_PING,
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
        guard seekStart == nil else { return }
        seekStart = time
    }
    
    func onSeeked(time: Double) {
        guard let seekStart, nextRequestTime != Self.STOP_PING else { return }
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
                guard let ads = pingResponse.ads else {
                    return
                }
                self.adScheduler.add(ads: ads)
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
