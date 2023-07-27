//
//  AdEventConvivaReporter.swift
//  
//
//  Created by Damiaan Dufaux on 07/09/2022.
//

import ConvivaSDK
import THEOplayerSDK

public class AdEventConvivaReporter: AdEventProcessor, ConvivaAdPlaybackEventsReporter {
    static let serializationFormatter: NumberFormatter = createSerializationFormatter()
    
    public let videoAnalytics: CISVideoAnalytics
    public let adAnalytics: CISAdAnalytics
    let storage: ConvivaConnectorStorage
        
    init(video: CISVideoAnalytics, ads: CISAdAnalytics, storage: ConvivaConnectorStorage) {
        videoAnalytics = video
        adAnalytics = ads
        self.storage = storage
    }
    
    public func adBreakBegin(event: AdBreakBeginEvent) {
        guard let adBreak = event.ad else { return }
        videoAnalytics.reportAdBreakStarted(.ADPLAYER_CONTENT, adType: .CLIENT_SIDE, adBreakInfo: [
            CIS_SSDK_AD_BREAK_POD_DURATION: Self.serialize(number: .init(value: adBreak.maxDuration)),
            CIS_SSDK_AD_BREAK_POD_INDEX: Self.serialize(number: .init(value: adBreak.timeOffset)),
            CIS_SSDK_AD_BREAK_POD_POSITION: Self.serialize(number: .init(value: adBreak.convivaAdPosition.rawValue))
        ])
    }
    
    public func adBreakEnd(event: AdBreakEndEvent) {
        videoAnalytics.reportAdBreakEnded()
    }
    
    public func adBegin(event: AdBeginWithDurationEvent) {
        guard let ad = event.beginEvent.ad, ad.type == THEOplayerSDK.AdType.linear else { return }

        var info = ad.convivaInfo
        
        // set Ad contentAssetName
        if let contentAssetName = self.storage.valueForKey(CIS_SSDK_METADATA_ASSET_NAME) {
            info["contentAssetName"] = contentAssetName
        }
        // set Ad session ID
        info["c3.csid"] = self.videoAnalytics.getSessionId()
        
        // Temporary workaround for missing LinearAd in Native THEOplayerGoogleIMAIntegration. Can be removed after THEO-10161 is completed.
        if !info.keys.contains(CIS_SSDK_METADATA_IS_LIVE), let duration = event.duration {
            if duration.isInfinite {
                info[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: true)
            } else {
                info[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: false)
                info[CIS_SSDK_METADATA_DURATION] = NSNumber(value: duration)
            }
        }

        adAnalytics.reportAdLoaded(info)
        adAnalytics.reportAdStarted(info)
        if let width = ad.width, let height = ad.height {
            adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_RESOLUTION, value: NSValue(
                cgSize: .init(width: width, height: height)
            ))
        }
    }
    
    public func adRenderedFramerateUpdate(framerate: Float) {
        adAnalytics.reportAdMetric(
            CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE,
            value: NSNumber(value: Int(framerate.rounded()))
        )
    }
    
    public func adEnd(event: AdEndEvent) {
        if event.ad?.type == THEOplayerSDK.AdType.linear {
            adAnalytics.reportAdEnded()
        }
    }
    
    public func adError(event: AdErrorEvent) {
        if let ad = event.ad {
            adAnalytics.reportAdFailed(
                event.error ?? "An error occured while playing ad \(ad.id ?? "without id")",
                adInfo: ad.convivaInfo
            )
        } else {
            adAnalytics.reportAdFailed(event.error ?? "An error occured while playing an ad", adInfo: nil)
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
    public static func serialize(number: NSNumber) -> String {
        serializationFormatter.string(from: number) ?? number.description(withLocale: Utilities.en_usLocale)
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
        result["c3.ad.technology"] = AdTechnology.CLIENT_SIDE
        result["c3.ad.isSlate"] = "false"
        result["c3.ad.creativeId"] = nonEmpty(googleImaAd?.creativeId) ?? Utilities.defaultStringValue
        result["c3.ad.system"] = nonEmpty(googleImaAd?.adSystem) ?? Utilities.defaultStringValue
        result["c3.ad.firstAdId"] = nonEmpty(googleImaAd?.wrapperAdIds.first) ?? nonEmpty(id) ?? Utilities.defaultStringValue
        result["c3.ad.firstCreativeId"] = nonEmpty(googleImaAd?.wrapperCreativeIds.first) ?? nonEmpty(googleImaAd?.creativeId) ?? Utilities.defaultStringValue
        result["c3.ad.firstAdSystem"] = nonEmpty(googleImaAd?.wrapperAdSystems.first) ?? nonEmpty(googleImaAd?.adSystem) ?? Utilities.defaultStringValue
        result["c3.ad.adStitcher"] = Utilities.defaultStringValue
        result["c3.ad.position"] = self.calculateCurrentAdBreakPosition(adBreak: self.adBreak)
        // linearAd specific
        if let linearAd = self as? LinearAd,
           let duration = linearAd.duration {
            result[CIS_SSDK_METADATA_IS_LIVE] = false
            result[CIS_SSDK_METADATA_DURATION] = NSNumber(value: Int(duration))
        }
        
        return result
    }
    
    private func calculateCurrentAdBreakPosition(adBreak: AdBreak?) -> String {
        guard let adBr = adBreak else {
            return "Mid-roll"
        }
        
        if adBr.timeOffset == 0 {
            return "Pre-roll"
        } else if adBr.timeOffset < 0 {
            return "Post-roll"
        } else {
            return "Mid-roll"
        }
    }
    
    private func nonEmpty(_ s: String?) -> String? {
        guard let string = s else {
            return nil
        }
        return string.count > 0 ? string : nil
    }
}

public protocol ConvivaAdPlaybackEventsReporter: AdPlaybackEventProcessor {
    var videoAnalytics: CISVideoAnalytics { get }
    var adAnalytics: CISAdAnalytics { get }
}

extension ConvivaAdPlaybackEventsReporter {
    public func adPlay(event: PlayEvent) {
        adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    public func adPlaying(event: PlayingEvent) {
        adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    public func adTimeUpdate(event: TimeUpdateEvent) {
        adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: event.currentTimeInMilliseconds)
    }
    
    public func adPause(event: PauseEvent) {
        adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
    }
}
