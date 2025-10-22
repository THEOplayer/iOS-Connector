//
//  AppStateConvivaReporter.swift
//  

import ConvivaSDK
import AVFoundation
import THEOplayerSDK

class AppHandler {
    private weak var storage: ConvivaStorage?
    private weak var endpoints: ConvivaEndpoints?
    
    init(endpoints: ConvivaEndpoints, storage: ConvivaStorage) {
        self.endpoints = endpoints
        self.storage = storage
    }
    
    func appWillEnterForeground(notification: Notification) {
        log("analytics.reportAppForegrounded")
        self.endpoints?.analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        log("analytics.reportAppBackgrounded")
        self.endpoints?.analytics.reportAppBackgrounded()
    }
    
    private func log(_ message: String) {
        if DEBUG_LOGGING {
            print("[THEOplayerConnector-Conviva] AppHandler: \(message)")
        }
    }
}
