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
    static let playerName = "THEOplayer"
    static let playerVersion = THEOplayer.version
    
    static let playerInfo = [
            CIS_SSDK_PLAYER_FRAMEWORK_NAME: playerName,
            CIS_SSDK_PLAYER_FRAMEWORK_VERSION: THEOplayer.version
        ]
    
    static let defaultStringValue = "NA"
    
    static let en_usLocale = Locale(identifier: "en_US")
    
    static func extendedContentInfo(contentInfo: [String: Any], storage: ConvivaConnectorStorage?) -> [String: Any] {
        var extendedContentInfo = contentInfo
        if let viewerId = storage?.valueForKey(CIS_SSDK_METADATA_VIEWER_ID) as? String {
            extendedContentInfo.updateValue(viewerId, forKey: CIS_SSDK_METADATA_VIEWER_ID)
        }
        extendedContentInfo.updateValue(Utilities.playerName, forKey: CIS_SSDK_METADATA_PLAYER_NAME)
        extendedContentInfo.updateValue(Utilities.playerName, forKey: CIS_SSDK_PLAYER_FRAMEWORK_NAME)
        extendedContentInfo.updateValue(Utilities.playerVersion, forKey: CIS_SSDK_PLAYER_FRAMEWORK_VERSION)
        return extendedContentInfo
    }
}

extension THEOplayer {
    var currentItem: AVPlayerItem? {
        ((Mirror(reflecting: self).descendant("theoplayer") as? NSObject).map {Mirror(reflecting: $0).superclassMirror?.descendant("mainContentPlayer", "avPlayer")} as? AVPlayer)?.currentItem
    }
    
    var renderedFramerate: Float? {
        currentItem?.tracks.first { $0.currentVideoFrameRate > 0 }?.currentVideoFrameRate
    }
}

extension CurrentTimeEvent {
    var currentTimeInMilliseconds: NSNumber {
        NSNumber(value: Int(currentTime * 1000))
    }
}
