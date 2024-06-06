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
    private let adIntegrationController: THEOplayerSDK.ServerSideAdIntegrationController
    private var adBreaksMap: [YOAdBreak : THEOplayerSDK.AdBreak] = [:]
    private var adsMap: [YOAdvert : THEOplayerSDK.Ad] = [:]
    private var currentAdBreak: YOAdBreak?
    private var currentAd: YOAdvert?

    init(session: YOSession, adIntegrationController: THEOplayerSDK.ServerSideAdIntegrationController) {
        self.session = session
        self.adIntegrationController = adIntegrationController
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
        guard let adBreak: YOAdBreak = notification.userInfo?[YOAdBreakKey] as? YOAdBreak else { return }
        print("** Adbreak start, Id:\(adBreak.identifier ?? "nil") duration:\(adBreak.duration ?? 0 ) \((adBreak.isActive()) == true ? "active": "inactive")")
        self.currentAdBreak = adBreak
        self.processAdBreak(yospaceAdBreak: adBreak)
    }

    @objc private func adBreakDidEnd(notification: Notification) {
        let currentAdBreak = notification.userInfo?[YOAdBreakKey] as? YOAdBreak
        print("** Adbreak end, Id:\(currentAdBreak?.identifier ?? "nil") duration:\(currentAdBreak?.duration ?? 0 ) \((currentAdBreak?.isActive()) == true ? "active": "inactive")")
    }

    @objc private func advertDidStart(notification: Notification) {
        guard let yospaceAd: YOAdvert = notification.userInfo?[YOAdvertKey] as? YOAdvert,
              let ad: THEOplayerSDK.Ad = self.adsMap[yospaceAd] else { return }
        print("** Advert start, filler: \(yospaceAd.isFiller), Id: \(yospaceAd.identifier), duration: \(yospaceAd.duration), isActive: (\(yospaceAd.isActive))")

        self.currentAd = yospaceAd
        self.adIntegrationController.beginAd(ad: ad)

        if yospaceAd.interactiveCreative != nil  {
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
        for adBreak: YOAdBreak in self.session.adBreaks(.linearType) as! Array<YOAdBreak>  {
            print("   * Adbreak, Id: \(adBreak.identifier ?? "") duration: \(adBreak.duration)")
            self.processAdBreak(yospaceAdBreak: adBreak)
        }
        for adBreak: YOAdBreak in self.session.adBreaks(.nonLinearType) as! Array<YOAdBreak> {
            print("   * Nonlinear Adbreak, Id: \(adBreak.identifier ?? "")")
            self.processAdBreak(yospaceAdBreak: adBreak)
        }
        for adBreak: YOAdBreak in self.session.adBreaks(.displayType) as! Array<YOAdBreak> {
            print("   * Display Adbreak, Id: \(adBreak.identifier ?? "")")
            self.processAdBreak(yospaceAdBreak: adBreak)
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

    private func processAdBreak(yospaceAdBreak: YOAdBreak) {
        let storedAdBreak: THEOplayerSDK.AdBreak? = self.adBreaksMap[yospaceAdBreak]
        let isNewEntry: Bool = storedAdBreak == nil

        let adBreak: THEOplayerSDK.AdBreak
        let adBreakInitParams: THEOplayerSDK.AdBreakInitParams = .init(timeOffset: Int(yospaceAdBreak.start), maxDuration: Int(yospaceAdBreak.duration))
        if isNewEntry {
            let newAdBreak: THEOplayerSDK.AdBreak = self.adIntegrationController.createAdBreak(params: adBreakInitParams)
            self.adBreaksMap[yospaceAdBreak] = newAdBreak
            adBreak = newAdBreak
        } else {
            adBreak = storedAdBreak!
            self.adIntegrationController.updateAdBreak(adBreak: adBreak, params: adBreakInitParams)
        }

        for case let advert as YOAdvert in yospaceAdBreak.adverts {
            print("   * Ad, Type: \(advert.adType) mediaId: \(advert.mediaIdentifier) duration: \(Int(advert.duration))")
            self.processAd(yospaceAd: advert, yospaceAdBreak: yospaceAdBreak)
        }
    }

    private func processAd(yospaceAd: YOAdvert, yospaceAdBreak: YOAdBreak) {
        let nonLinearCreative: YONonLinearCreative? = (yospaceAd.nonLinearCreatives(.YOStaticResource) as? [YONonLinearCreative])?.first
        let staticResource: YOResource? = nonLinearCreative?.resources()[YOResourceType.YOStaticResource] as? YOResource
        var width: Int?
        var height: Int?
        if let _width: String = nonLinearCreative?.property("width")?.value {
            width = Int(_width)
        }
        if let _height: String = nonLinearCreative?.property("height")?.value {
            height = Int(_height)
        }
        let duration: Int? = Int(yospaceAd.duration)
        var type: String = THEOplayerSDK.AdType.unknown
        if yospaceAdBreak.breakType == .linearType {
            type = THEOplayerSDK.AdType.linear
        } else if yospaceAdBreak.breakType == .nonLinearType {
            type = THEOplayerSDK.AdType.nonlinear
        }
        let adInitParams: AdInitParams = .init(type: type, timeOffset: yospaceAd.start, companions: [], id: yospaceAd.mediaIdentifier, skipOffset: Int(yospaceAd.skipOffset), resourceURI: staticResource?.stringData, width: width, height: height, duration: duration)

        let storedAd: THEOplayerSDK.Ad? = self.adsMap[yospaceAd]
        let isNewEntry: Bool = storedAd == nil

        let ad: THEOplayerSDK.Ad
        if isNewEntry,
           let adBreak: THEOplayerSDK.AdBreak = self.adBreaksMap[yospaceAdBreak] {
            let newAd: THEOplayerSDK.Ad = self.adIntegrationController.createAd(params: adInitParams, adBreak: adBreak)
            self.adsMap[yospaceAd] = newAd
            ad = newAd
        } else {
            ad = storedAd!
            self.adIntegrationController.updateAd(ad: ad, params: adInitParams)
        }
    }

    private func reset() {
        self.removeNotificationObservers(session: self.session)
        self.adBreaksMap = [:]
        self.adsMap = [:]
        self.currentAdBreak = nil
        self.currentAd = nil
    }

    deinit {
        self.reset()
    }
}
