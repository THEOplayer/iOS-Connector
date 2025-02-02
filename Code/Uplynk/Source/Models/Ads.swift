//
//  File.swift
//  
//
//  Created by Khalid, Yousif on 31/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.

import Foundation

public struct UplynkAd: Codable {
    /// Indicates the API Framework for the ad (e.g., VPAID).
    public let apiFramework: String?
    
    /// List of companion ads that go with the ad. Companion ads are also ad objects.
    public let companions: [UplynkAd]
    
    /// Indicates the ad's Internet media type (aka mime-type). Examples are:  uplynk/m3u8 | application/javascript
    public let mimeType: String
    
    /// If applicable, indicates the creative to display.
    /// Video Ad (CMS): Indicates the asset ID for the video ad pushed from the CMS.
    /// Video Ad (VPAID): Indicates the URL to the VPAID JS or SWF.
    public let creative: String?
    
    //TODO: Implement events
    
    /// If applicable, indicates the width of the creative. This parameter will report "0" for the width/height of video ads.
    public let width: Float
    /// If applicable, indicates the height of the creative.
    public let height: Float
    /// Indicates the duration, in seconds, of an ad's encoded video.
    public let duration: Float
    
    //TODO: Implement extensions
    
    /// If the ad response provided by FreeWheel contains creative parameters, they will be reported as name-value pairs within this object.
    public let fw_parameters: Dictionary<String, String>?
}

public struct UplynkAdBreak: Codable {
    /// Contains events for the ad break.
    //TODO: Implement this
    //let events:
    
    /// A list of ad objects associated with this ad break.
    public let ads: [UplynkAd]
    /// Indicates the ad break type. Valid values are: linear | nonlinear
    public let type: String
    /// Indicates the position of the ad break. Valid values are: preroll | midroll | postroll | pause | overlay
    public let position: String
    /// Indicates the start time of the ad break in the player timeline.
    public let timeOffset: Float
    /// Indicates the duration of the ad break.
    public let duration: Float
    
}
public struct UplynkAdBreakOffset: Codable {
    /// the ad break's timeOffset
    public let timeOffset: Float
    /// the index for the ads.breaks object.
    public let index: Int
}

public struct UplynkPlaceHolderOffset: Codable {
    /// Indicates the starting time of the placeholder ad. This value is in player time for the entire m3u8 timeline.
    public let startTime: Float
    /// Indicates the ending time of the placeholder ad.
    public let endTime: Float
    /// Indicates the index in the ads.breaks array that contains the VPAID ad that was replaced.
    public let breakIndex: Int
    /// Indicates the index in the ads.breaks.ads array that identifies the location for VPAID ad information.
    public let adsIndex: Int
}

public struct UplynkAds: Codable {
    /// A list of objects for every ad break in the ad response. This includes both linear and non-linear ads. For more information on the difference between linear and non-linear ads, see the VAST 3 specification document.
    public let breaks: [UplynkAdBreak]
    /// A list of objects that contain the ad break's timeOffset and the index for the ads.breaks object.
    public let breakOffsets: [UplynkAdBreakOffset]
    /// A list of objects with start and end times for every non-video ad that has been replaced with a short blank video (i.e., placeholder ad).
    public let placeholderOffsets: [UplynkPlaceHolderOffset]
}
