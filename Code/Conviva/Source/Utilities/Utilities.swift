//
//  Utilities.swift
//  
//
//  Created by Damiaan Dufaux on 31/08/2022.
//
import Foundation
import ConvivaSDK
import THEOplayerSDK

enum Utilities {
    static let playerFrameworkName = "THEOplayer"
    
    static let playerInfo = [
        CIS_SSDK_PLAYER_FRAMEWORK_NAME: playerFrameworkName,
        CIS_SSDK_PLAYER_FRAMEWORK_VERSION: THEOplayer.version
    ]
    
    static let defaultStringValue = "NA"
    
    static let en_usLocale = Locale(identifier: "en_US")
}

extension CurrentTimeEvent {
    var currentTimeInMilliseconds: NSNumber {
        NSNumber(value: Int(currentTime * 1000))
    }
}
