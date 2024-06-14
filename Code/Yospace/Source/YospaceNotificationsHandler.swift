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
    private let player: THEOplayerSDK.THEOplayer
    private var adBreaksMap: [YOAdBreak : THEOplayerSDK.AdBreak] = [:]
    private var adsMap: [YOAdvert : THEOplayerSDK.Ad] = [:]
    private var currentAdBreak: YOAdBreak?
    private var currentAd: YOAdvert?

    init(session: YOSession, adIntegrationController: THEOplayerSDK.ServerSideAdIntegrationController, player: THEOplayerSDK.THEOplayer) {
        self.session = session
        self.adIntegrationController = adIntegrationController
        self.player = player
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
        self.currentAdBreak = adBreak
        self.processAdBreak(yospaceAdBreak: adBreak)
    }

    @objc private func adBreakDidEnd(notification: Notification) {
        guard let yospaceAdBreak: YOAdBreak = self.currentAdBreak,
              let adBreak: THEOplayerSDK.AdBreak = self.adBreaksMap[yospaceAdBreak] else {
            return
        }
        self.adIntegrationController.removeAdBreak(adBreak: adBreak)
        self.currentAdBreak = nil
    }

    @objc private func advertDidStart(notification: Notification) {
        guard let yospaceAd: YOAdvert = notification.userInfo?[YOAdvertKey] as? YOAdvert,
              let ad: THEOplayerSDK.Ad = self.adsMap[yospaceAd] else { return }
        self.currentAd = yospaceAd
        self.adIntegrationController.beginAd(ad: ad)
    }

    @objc private func advertDidEnd(notification: Notification) {
        guard let yospaceAd: YOAdvert = self.currentAd,
              let ad: THEOplayerSDK.Ad = self.adsMap[yospaceAd] else { return }
        self.adIntegrationController.endAd(ad: ad)
        self.currentAd = nil
    }

    @objc private func trackingEventDidOccur(notification: Notification) {
        let name = notification.userInfo?[YOEventNameKey] as! String
        let progressEventsList: [String] = ["firstQuartile", "midpoint", "thirdQuartile"]
        guard let currentAd: YOAdvert = self.currentAd,
              let ad: THEOplayerSDK.Ad = self.adsMap[currentAd],
              progressEventsList.contains(name) else { return }
        let remaining: Double = currentAd.remainingTime(self.player.currentTime)
        let duration: Double = currentAd.duration
        let progress: Double = (duration - remaining) / duration
        // avoid reporting updates when skipping; values should be in the range of [0.25, 0.75]
        if progress < 1 {
            self.adIntegrationController.updateAdProgress(ad: ad, progress: progress)
        }
    }

    @objc private func analyticUpdateDidOccur(notification: NSNotification) {
        for adBreak: YOAdBreak in self.session.adBreaks(.linearType) as! Array<YOAdBreak>  {
            self.processAdBreak(yospaceAdBreak: adBreak)
        }
        for adBreak: YOAdBreak in self.session.adBreaks(.nonLinearType) as! Array<YOAdBreak> {
            self.processAdBreak(yospaceAdBreak: adBreak)
        }
        for adBreak: YOAdBreak in self.session.adBreaks(.displayType) as! Array<YOAdBreak> {
            self.processAdBreak(yospaceAdBreak: adBreak)
        }
    }

    @objc private func sessionErrorDidOccur(notification: Notification) {
        let info = notification.userInfo
        let code: NSNumber? = info?[YOErrorCodeKey] as? NSNumber

        if code == NSNumber(value: YOSessionError.sessionTimeout.rawValue) {
            let error = YospaceError.error(msg: YOSessionError.sessionTimeout.errorMessage)
            self.adIntegrationController.error(error: error)
            self.session.shutdown()
        } else if code == NSNumber(value: YOSessionError.unresolvedBreak.rawValue) {
            let error = YospaceError.error(msg: YOSessionError.unresolvedBreak.errorMessage)
            self.adIntegrationController.error(error: error)
        } else if code == NSNumber(value: YOSessionError.parseError.rawValue) {
            let errors: Array<YOTrackingError> = self.session.parsingErrors() as! Array<YOTrackingError>
            errors.forEach { parsingError in
                let error = YospaceError.error(msg: YOSessionError.parseError.errorMessage + "Parsing error: \(parsingError.toJsonString())")
                self.adIntegrationController.error(error: error)
            }
        }
    }

    @objc private func adBreakDidEndEarly(notification: Notification) {
        let currentAdBreak = notification.userInfo?[YOAdBreakKey] as? YOAdBreak
        if let currentAd: YOAdvert = self.currentAd,
           let ad: THEOplayerSDK.Ad = self.adsMap[currentAd] {
            self.adIntegrationController.skipAd(ad: ad)
            self.currentAd = nil
        }
        self.adBreakDidEnd(notification: notification)
    }

    @objc private func trackingErrorDidOccur(notification: Notification) {
        let info = notification.userInfo
        let trackingError: YOTrackingError = info?[YOTrackingErrorKey] as! YOTrackingError
        let error = YospaceError.error(msg: "Yospace: Tracking error \(trackingError.toJsonString())")
        self.adIntegrationController.error(error: error)
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
        let adBreakInitParams: AdBreakInitParams = .init(timeOffset: Int(yospaceAdBreak.start), maxDuration: Int(yospaceAdBreak.duration))
        if isNewEntry {
            let newAdBreak: THEOplayerSDK.AdBreak = self.adIntegrationController.createAdBreak(params: adBreakInitParams)
            self.adBreaksMap[yospaceAdBreak] = newAdBreak
            adBreak = newAdBreak
        } else {
            adBreak = storedAdBreak!
            self.adIntegrationController.updateAdBreak(adBreak: adBreak, params: adBreakInitParams)
        }

        for case let advert as YOAdvert in yospaceAdBreak.adverts {
            self.processAd(yospaceAd: advert, yospaceAdBreak: yospaceAdBreak)
        }
    }

    private func processAd(yospaceAd: YOAdvert, yospaceAdBreak: YOAdBreak) {
        let nonLinearCreative: YONonLinearCreative? = (yospaceAd.nonLinearCreatives(.YOStaticResource) as? [YONonLinearCreative])?.first
        let staticResource: YOResource? = nonLinearCreative?.resources()[YOResourceType.YOStaticResource.rawValue] as? YOResource
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
        var clickThrough: String?
        if yospaceAdBreak.breakType == .linearType {
            type = THEOplayerSDK.AdType.linear
            clickThrough = yospaceAd.linearCreative.clickthroughUrl()
        } else if yospaceAdBreak.breakType == .nonLinearType {
            type = THEOplayerSDK.AdType.nonlinear
            clickThrough = nonLinearCreative?.clickthroughUrl()
        }
        let adInitParams: AdInitParams = .init(integration: .defaultKind, type: type, companions: [], timeOffset: yospaceAd.start, adBreak: self.adBreaksMap[yospaceAdBreak], id: yospaceAd.mediaIdentifier, skipOffset: Int(yospaceAd.skipOffset), resourceURI: staticResource?.stringData, width: width, height: height, duration: duration, clickThrough: clickThrough)

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

fileprivate struct AdInitParams: THEOplayerSDK.AdInit {
    var integration: THEOplayerSDK.AdIntegrationKind
    var type: String
    var companions: [THEOplayerSDK.CompanionAd?]
    var timeOffset: Double?
    var adBreak: THEOplayerSDK.AdBreak?
    var id: String?
    var skipOffset: Int?
    var resourceURI: String?
    var width: Int?
    var height: Int?
    var duration: Int?
    var clickThrough: String?

    init(integration: THEOplayerSDK.AdIntegrationKind, type: String, companions: [THEOplayerSDK.CompanionAd?], timeOffset: Double? = nil, adBreak: THEOplayerSDK.AdBreak? = nil, id: String? = nil, skipOffset: Int? = nil, resourceURI: String? = nil, width: Int? = nil, height: Int? = nil, duration: Int? = nil, clickThrough: String? = nil) {
        self.type = type
        self.timeOffset = timeOffset
        self.adBreak = adBreak
        self.companions = companions
        self.id = id
        self.skipOffset = skipOffset
        self.resourceURI = resourceURI
        self.width = width
        self.height = height
        self.integration = integration
        self.duration = duration
        self.clickThrough = clickThrough
    }
}

fileprivate struct AdBreakInitParams: THEOplayerSDK.AdBreakInit {
    var timeOffset: Int
    var maxDuration: Int?

    init(timeOffset: Int, maxDuration: Int? = nil) {
        self.timeOffset = timeOffset
        self.maxDuration = maxDuration
    }
}
