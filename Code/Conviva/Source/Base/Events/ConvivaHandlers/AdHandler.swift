//
//  AdEventConvivaReporter.swift
//  

import ConvivaSDK
import THEOplayerSDK

class AdHandler {
    static let serializationFormatter: NumberFormatter = createSerializationFormatter()
    private weak var endpoints: ConvivaEndpoints?
    private weak var storage: ConvivaStorage?
        
    init(endpoints: ConvivaEndpoints, storage: ConvivaStorage) {
        self.endpoints = endpoints
        self.storage = storage
    }
    
    func setAdInfo(_ adInfo: [String: Any]) {
        log("adAnalytics.setAdInfo: \(adInfo)")
        self.endpoints?.adAnalytics.setAdInfo(adInfo)
    }
    
    private func calculatedAdTechnology(_ integrationKind: AdIntegrationKind) -> AdTechnology {
        switch integrationKind {
        case AdIntegrationKind.theoads:
            // TODO THEOads is an SGAI solution which can't be reported to Conviva as such yet
            return .SERVER_SIDE
        case AdIntegrationKind.google_ima:
            return .CLIENT_SIDE
        default:
            return .SERVER_SIDE
        }
    }
    
    private func AdTechnologyAsString(_ integration: AdIntegrationKind) -> String {
        if integration == AdIntegrationKind.theoads {
            return "Server Guided"
        }
        let adTechnology = self.calculatedAdTechnology(integration)
        switch adTechnology {
        case .CLIENT_SIDE:
            return "Client Side"
        case .SERVER_SIDE:
            return "Server Side"
        default:
            return "unknown"
        }
    }
    
    func adPlay(event: PlayEvent) {
        log("handling adPlay")
        log("adAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_PLAYING]")
        self.endpoints?.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    func adPlaying(event: PlayingEvent) {
        log("handling adPlaying")
        log("adAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_PLAYING]")
        self.endpoints?.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    func adTimeUpdate(event: TimeUpdateEvent) {
        //log("adTimeUpdate")
        //log("adAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME : \(event.currentTimeInMilliseconds)]")
        self.endpoints?.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: event.currentTimeInMilliseconds)
    }
    
    func adPause(event: PauseEvent) {
        log("handling adPause")
        log("adAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_PAUSED]")
        self.endpoints?.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
    }
    
    func adBreakBegin(event: AdBreakBeginEvent) {
        log("handling adBreakBegin")
        guard let adBreak = event.ad else { return }
        let adBreakInfo = [
            CIS_SSDK_AD_BREAK_POD_DURATION: Self.serialize(number: .init(value: adBreak.maxDuration)),
            CIS_SSDK_AD_BREAK_POD_INDEX: Self.serialize(number: .init(value: adBreak.timeOffset)),
            CIS_SSDK_AD_BREAK_POD_POSITION: adBreak.calculateCurrentAdBreakPosition(),
            "podTechnology": self.AdTechnologyAsString(adBreak.integration)
        ]
        log("videoAnalytics.reportAdBreakStarted: \(adBreakInfo)]")
        self.endpoints?.videoAnalytics.reportAdBreakStarted(
            .ADPLAYER_CONTENT,
            adType: self.calculatedAdTechnology(adBreak.integration),
            adBreakInfo: adBreakInfo
        )
    }
    
    func adBreakEnd(event: AdBreakEndEvent) {
        log("handling adBreakEnd")
        log("videoAnalytics.reportAdBreakEnded")
        self.endpoints?.videoAnalytics.reportAdBreakEnded()
    }
    
    func adBegin(event: AdBeginWithDurationEvent) {
        log("handling adBegin")
        guard let ad = event.beginEvent.ad, ad.type == THEOplayerSDK.AdType.linear else { return }

        var info = ad.convivaInfo

        let adTechnology = self.AdTechnologyAsString(ad.integration)
        // set Ad technology
        info["c3.ad.technology"] = adTechnology
        
        // set Ad contentAssetName
        if let contentAssetName = self.storage?.metadataEntryForKey(CIS_SSDK_METADATA_ASSET_NAME) {
            info["contentAssetName"] = contentAssetName
        }
        // set Ad session ID
        if let videoAnalytics = self.endpoints?.videoAnalytics {
            info["c3.csid"] = videoAnalytics.getSessionId()
        }
        
        // Temporary workaround for missing LinearAd in Native THEOplayerGoogleIMAIntegration. Can be removed after THEO-10161 is completed.
        if !info.keys.contains(CIS_SSDK_METADATA_IS_LIVE), let duration = event.duration {
            if duration.isInfinite {
                info[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: true)
            } else {
                info[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: false)
                info[CIS_SSDK_METADATA_DURATION] = NSNumber(value: duration)
            }
        }

        log("adAnalytics.reportAdLoaded: \(info)")
        self.endpoints?.adAnalytics.reportAdLoaded(info)
        log("adAnalytics.reportAdStarted: \(info)")
        self.endpoints?.adAnalytics.reportAdStarted(info)
        if let width = ad.width, let height = ad.height {
            let resolution = NSValue(cgSize: .init(width: width, height: height))
            log("adAnalytics.reportAdMetric [CIS_SSDK_PLAYBACK_METRIC_RESOLUTION : \(resolution)]")
            self.endpoints?.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_RESOLUTION, value: resolution)
        }
        
        if self.calculatedAdTechnology(ad.integration) == .SERVER_SIDE {
            log("adAnalytics.reportAdMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_PLAYING]")
            self.endpoints?.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
        }
    }
    
    func adRenderedFramerateUpdate(framerate: Float) {
        //log("adRenderedFramerateUpdate")
        let framerate = NSNumber(value: Int(framerate.rounded()))
        //log("adAnalytics.reportAdMetric [CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE, \(framerate)]")
        self.endpoints?.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE, value: framerate)
    }
    
    func adEnd(event: AdEndEvent) {
        log("handling adEnd")
        if event.ad?.type == THEOplayerSDK.AdType.linear {
            self.endpoints?.adAnalytics.reportAdEnded()
        }
    }
    
    func adError(event: AdErrorEvent) {
        log("handling adError")
        if let ad = event.ad {
            let message = event.error ?? "An error occured while playing ad \(ad.id ?? "without id")"
            log("adAnalytics.reportAdFailed: \(message)")
            self.endpoints?.adAnalytics.reportAdFailed(message, adInfo: ad.convivaInfo)
        } else {
            let message = event.error ?? "An error occured while playing an ad"
            log("adAnalytics.reportAdFailed: \(message)")
            self.endpoints?.adAnalytics.reportAdFailed(message, adInfo: nil)
        }
    }
        
    static func createSerializationFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 6
        return formatter
    }
    
    /// Serializes a number into a string without 'grouping separators' and using a `"."` as decimal separator
    static func serialize(number: NSNumber) -> String {
        self.serializationFormatter.string(from: number) ?? number.description(withLocale: Utilities.en_usLocale)
    }
    
    private func log(_ message: String) {
        if DEBUG_LOGGING {
            print("[THEOplayerConnector-Conviva] AdHandler: \(message)")
        }
    }
}

extension AdBreak {
    func calculateCurrentAdBreakPosition() -> String {
        if self.timeOffset == 0 {
            return "Pre-roll"
        } else if self.timeOffset < 0 {
            return "Post-roll"
        } else {
            return "Mid-roll"
        }
    }
}

extension Ad {
    /// A dictionary containing all the ad info that can be passed to `CISAdAnalytics`'s `setAdInfo(_ convivaInfo: [:])` function.
    var convivaInfo: [AnyHashable: Any] {
        let googleImaAd = self as? GoogleImaAd
        var result: [AnyHashable: Any] = Utilities.playerInfo
        let assetName = nonEmpty(id) ?? Utilities.defaultStringValue
        result[CIS_SSDK_METADATA_ASSET_NAME] = assetName
        result[CIS_SSDK_METADATA_STREAM_URL] = resourceURI ?? Utilities.defaultStringValue
        result["c3.ad.id"] = nonEmpty(id) ?? Utilities.defaultStringValue
        result["c3.ad.creativeName"] = assetName
        result["c3.ad.isSlate"] = "false"
        result["c3.ad.creativeId"] = nonEmpty(googleImaAd?.creativeId) ?? Utilities.defaultStringValue
        result["c3.ad.system"] = nonEmpty(googleImaAd?.adSystem) ?? Utilities.defaultStringValue
        result["c3.ad.firstAdId"] = nonEmpty(googleImaAd?.wrapperAdIds.first) ?? nonEmpty(id) ?? Utilities.defaultStringValue
        result["c3.ad.firstCreativeId"] = nonEmpty(googleImaAd?.wrapperCreativeIds.first) ?? nonEmpty(googleImaAd?.creativeId) ?? Utilities.defaultStringValue
        result["c3.ad.firstAdSystem"] = nonEmpty(googleImaAd?.wrapperAdSystems.first) ?? nonEmpty(googleImaAd?.adSystem) ?? Utilities.defaultStringValue
        result["c3.ad.adStitcher"] = Utilities.defaultStringValue
        result["c3.ad.position"] = self.adBreak.calculateCurrentAdBreakPosition()
        // linearAd specific
        if self.type == THEOplayerSDK.AdType.linear, let duration = self.duration {
            result[CIS_SSDK_METADATA_IS_LIVE] = false
            result[CIS_SSDK_METADATA_DURATION] = NSNumber(value: Int(duration))
        }
        return result
    }
    
    private func nonEmpty(_ s: String?) -> String? {
        guard let string = s else {
            return nil
        }
        return string.count > 0 ? string : nil
    }
}
