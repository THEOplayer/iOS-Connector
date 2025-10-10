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
}

extension THEOplayer {
    var currentItem: AVPlayerItem? {
        let basePlayer = (Mirror(reflecting: self).descendant("theoplayer") as? NSObject).map { Mirror(reflecting: $0).superclassMirror?.descendant("basePlayer") } as? AnyObject
        let basePlayerMirror = basePlayer.map { Mirror(reflecting: $0) }
        let avPlayer = basePlayerMirror?.superclassMirror?.superclassMirror?.descendant("player", "avPlayer") as? AVPlayer
        return avPlayer?.currentItem
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
