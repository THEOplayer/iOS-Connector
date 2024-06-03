//
//  YospaceNotificationsHandler.swift
//
//  Created by Raffi on 03/06/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

class YospaceNotificationsHandler {
    private let session: YOSession

    init(session: YOSession) {
        self.session = session
        self.addNotificationObservers(session: session)
    }

    private func addNotificationObservers(session: YOSession) {
        NotificationCenter.default.addObserver(self, selector: #selector(adBreakDidStart), name: .YOAdvertBreakStart, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(adBreakDidEnd), name: .YOAdvertBreakEnd, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(advertDidStart), name: .YOAdvertStart, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(advertDidEnd), name: .YOAdvertEnd, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(trackingEventDidOccur), name: .YOTrackingEvent, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(analyticUpdateDidOccur), name: .YOAnalyticUpdate, object: session)
        NotificationCenter.default.addObserver(self,selector: #selector(sessionErrorDidOccur), name: .YOSessionError, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(adBreakDidEndEarly), name: .YOAdBreakEarlyReturn, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(trackingErrorDidOccur), name: .YOTrackingError, object: session)
    }

    @objc private func adBreakDidStart(notification: Notification) {
        let currentAdBreak = notification.userInfo?[YOAdBreakKey] as? YOAdBreak
        print("** Adbreak start, Id:\(currentAdBreak?.identifier ?? "nil") duration:\(currentAdBreak?.duration ?? 0 ) \((currentAdBreak?.isActive()) == true ? "active": "inactive")")
    }

    @objc private func adBreakDidEnd(notification: Notification) {
        let currentAdBreak = notification.userInfo?[YOAdBreakKey] as? YOAdBreak
        print("** Adbreak end, Id:\(currentAdBreak?.identifier ?? "nil") duration:\(currentAdBreak?.duration ?? 0 ) \((currentAdBreak?.isActive()) == true ? "active": "inactive")")
    }

    @objc private func advertDidStart(notification: Notification) {
        let currentAdvert = notification.userInfo?[YOAdvertKey] as? YOAdvert
        print("** Advert start \(currentAdvert?.isFiller ?? false ? "(filler)":""), Id:\(currentAdvert?.identifier ?? "") duration:\(currentAdvert?.duration ?? 0) (\(currentAdvert?.isActive ?? false ? "active":"inactive"))")

        if currentAdvert?.interactiveCreative != nil  {
            // here the Interactive Creative data can be retrieved and passed to the renderer to display over the advert as required
            print ("** Advert is an Interactive media")
        }
    }

    @objc private func advertDidEnd(notification: Notification) {
        let currentAdvert = notification.userInfo?[YOAdvertKey] as? YOAdvert
        print("** Advert end \(currentAdvert?.isFiller ?? false ? "(filler)" : "")")
    }

    @objc private func trackingEventDidOccur(notification: Notification) {
        let name = notification.userInfo?[YOEventNameKey] as! String
        print("** Tracking event: \(name )")
    }

    @objc private func analyticUpdateDidOccur(notification: NSNotification) {
        print("** Analytic update")
        for adbreak: YOAdBreak in self.session.adBreaks(.linearType) as! Array<YOAdBreak>  {
            print("   * Adbreak, Id: \(adbreak.identifier ?? "") duration: \(adbreak.duration)")
        }
        for adbreak: YOAdBreak in self.session.adBreaks(.nonLinearType) as! Array<YOAdBreak> {
            print("   * Nonlinear Adbreak, Id: \(adbreak.identifier ?? "")")
        }
        for adbreak: YOAdBreak in self.session.adBreaks(.displayType) as! Array<YOAdBreak> {
            print("   * Display Adbreak, Id: \(adbreak.identifier ?? "")")
        }
    }

    @objc private func sessionErrorDidOccur(notification: Notification) {
        let info = notification.userInfo
        let code: NSNumber = info?[YOErrorCodeKey] as! NSNumber
        print("** Session error \(code.intValue)")

        if (code == NSNumber(value: YOSessionError.sessionTimeout.rawValue)) {
            // the session is no longer valid; a production app might recover by starting a new Session.
            self.session.shutdown()
        } else if (code == NSNumber(value: YOSessionError.unresolvedBreak.rawValue)) {
            // a production app might handle this error by modifying playback policy logic
        } else if (code == NSNumber(value: YOSessionError.parseError.rawValue)) {
            // a production app might send these to a third party measurement library
            let errors: Array<YOTrackingError> = self.session.parsingErrors() as! Array<YOTrackingError>
            errors.forEach { parsingError in
                print("Parsing error: \(parsingError.toJsonString())")
            }
        }
    }

    @objc private func adBreakDidEndEarly(notification: Notification) {
        let currentAdBreak = notification.userInfo?[YOAdBreakKey] as? YOAdBreak
        print("** Early return, Id:\(currentAdBreak?.identifier ?? "nil")")
    }

    @objc private func trackingErrorDidOccur(notification: Notification) {
        let info = notification.userInfo
        let error: YOTrackingError = info?[YOTrackingErrorKey] as! YOTrackingError
        print("** Tracking error \(error.toJsonString())")
    }

    private func removeNotificationObservers(session: YOSession) {
        NotificationCenter.default.removeObserver(self, name: .YOAdvertBreakStart, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOAdvertBreakEnd, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOAdvertStart, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOAdvertEnd, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOTrackingEvent, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOAnalyticUpdate, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOSessionError, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOAdBreakEarlyReturn, object: session)
        NotificationCenter.default.removeObserver(self, name: .YOTrackingError, object: session)
    }

    private func reset() {
        self.removeNotificationObservers(session: self.session)
    }

    deinit {
        self.reset()
    }
}
