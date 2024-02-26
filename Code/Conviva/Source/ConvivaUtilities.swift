//
//  Utilities.swift
//  
//
//  Created by Damiaan Dufaux on 31/08/2022.
//
import Foundation
import ConvivaSDK
import THEOplayerSDK
import AVFoundation

enum Utilities {
    static let playerFrameworkName = "THEOplayer"
    
    static let playerInfo = [
        CIS_SSDK_PLAYER_FRAMEWORK_NAME: playerFrameworkName,
        CIS_SSDK_PLAYER_FRAMEWORK_VERSION: THEOplayer.version
    ]
    
    static let defaultStringValue = "NA"
    
    static let en_usLocale = Locale(identifier: "en_US")
}

extension THEOplayer {
    var currentItem: AVPlayerItem? {
        ((Mirror(reflecting: self).descendant("theoplayer") as? NSObject).map {Mirror(reflecting: $0).superclassMirror?.descendant("mainContentPlayer", "avPlayer")} as? AVPlayer)?.currentItem
    }
    
    var renderedFramerate: Float? {
        currentItem?.tracks.first { $0.currentVideoFrameRate > 0 }?.currentVideoFrameRate
    }
    
    var hasAdsIntegration: Bool {
        getAllIntegrations().contains { $0.type == .ADS }
    }
}

extension CurrentTimeEvent {
    var currentTimeInMilliseconds: NSNumber {
        NSNumber(value: Int(currentTime * 1000))
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

extension AdBreak {
    var convivaAdPosition: AdPosition {
        switch timeOffset {
        case 0   : return .ADPOSITION_PREROLL
        case ..<0: return .ADPOSITION_POSTROLL
        default:   return .ADPOSITION_MIDROLL
        }
    }
}
