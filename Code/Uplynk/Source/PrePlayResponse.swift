//
//  PreplayResponse.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

struct UplynkAd: Codable {
    /// Indicates the API Framework for the ad (e.g., VPAID).
    let apiFramework: String
    
    /// List of companion ads that go with the ad. Companion ads are also ad objects.
    let companions: [UplynkAd]
    
    /// Indicates the ad's Internet media type (aka mime-type). Examples are:  uplynk/m3u8 | application/javascript
    let mimeType: String
    
    /// If applicable, indicates the creative to display.
    /// Video Ad (CMS): Indicates the asset ID for the video ad pushed from the CMS.
    /// Video Ad (VPAID): Indicates the URL to the VPAID JS or SWF.
    let creative: String
    
    //TODO: Implement events
    
    /// If applicable, indicates the width of the creative. This parameter will report "0" for the width/height of video ads.
    let width: Float
    /// If applicable, indicates the height of the creative.
    let height: Float
    /// Indicates the duration, in seconds, of an ad's encoded video.
    let duration: Float
    
    //TODO: Implement extensions
    
    /// If the ad response provided by FreeWheel contains creative parameters, they will be reported as name-value pairs within this object.
    let fw_parameters: Dictionary<String, String>
}

struct UplynkAdBreak: Codable {
    /// Contains events for the ad break.
    //TODO: Implement this
    //let events:
    
    /// A list of ad objects associated with this ad break.
    let ads: [UplynkAd]
    /// Indicates the ad break type. Valid values are: linear | nonlinear
    let type: String
    /// Indicates the position of the ad break. Valid values are: preroll | midroll | postroll | pause | overlay
    let position: String
    /// Indicates the start time of the ad break in the player timeline.
    let timeOffset: Float
    /// Indicates the duration of the ad break.
    let duration: Float
    
}
struct UplynkAdBreakOffset: Codable {
    /// the ad break's timeOffset
    let timeOffset: Float
    /// the index for the ads.breaks object.
    let index: Int
}

struct UplynkPlaceHolderOffset: Codable {
    /// Indicates the starting time of the placeholder ad. This value is in player time for the entire m3u8 timeline.
    let startTime: Float
    /// Indicates the ending time of the placeholder ad.
    let endTime: Float
    /// Indicates the index in the ads.breaks array that contains the VPAID ad that was replaced.
    let breakIndex: Int
    /// Indicates the index in the ads.breaks.ads array that identifies the location for VPAID ad information.
    let adsIndex: Int
}

struct UplynkAds: Codable {
    /// A list of objects for every ad break in the ad response. This includes both linear and non-linear ads. For more information on the difference between linear and non-linear ads, see the VAST 3 specification document.
    let breaks: [UplynkAdBreak]
    /// A list of objects that contain the ad break's timeOffset and the index for the ads.breaks object.
    let breakOffsets: [UplynkAdBreakOffset]
    /// A list of objects with start and end times for every non-video ad that has been replaced with a short blank video (i.e., placeholder ad).
    let placeholderOffsets: [UplynkPlaceHolderOffset]
}

protocol PrePlayResponseProtocol {
    /// Indicates the playback URL sent to the player.
    var playURL: String {get}
    /// Indicates the playback session ID.
    var sid: String {get}
    /// Indicates the zone prefix (e.g., https://content-ause2.uplynk.com/) for the viewer's session. Use this prefix when submitting playback or API requests (e.g., Ping endpoint) for this session.
    var prefix: String {get}
    /// The response may include this object when Studio DRM has been activated on your account.
    var drm: PrePlayDRMConfiguration? {get}
}

struct UplynkLiveAd: Codable {
    /// Indicates the duration, in seconds, of an ad break.
    let duration: Float
    /// Indicates the start time, in Unix time, of an ad break.
    let ts: Float
    /// If the ad response provided by FreeWheel contains creative parameters, they will be reported as name-value pairs within this object.
    let fw_parameters: Dictionary<String, String>
    //TODO: Add extensions
}

struct PrePlayDRMConfiguration: Codable {
    /// Indicates whether Studio DRM is required for playback.
    let required: Bool
    /// Indicates the URL to a hosted instance of your public FPS certificate.
    let fairplayCertificateURL: String
}

struct PrePlayLiveResponse: PrePlayResponseProtocol, Codable {
    /// Indicates the playback URL sent to the player.
    let playURL: String
    /// Indicates the playback session ID.
    let sid: String
    /// Indicates the zone prefix (e.g., https://content-ause2.uplynk.com/) for the viewer's session. Use this prefix when submitting playback or API requests (e.g., Ping endpoint) for this session.
    let prefix: String
    /// Contains a list of ads that took place during the time period defined by the ts and endts request parameters.
    let ads: [UplynkLiveAd]
    /// The response may include this object when Studio DRM has been activated on your account.
    let drm: PrePlayDRMConfiguration?
    
}

struct PrePlayVODResponse: PrePlayResponseProtocol, Codable {
    /// Indicates the playback URL sent to the player.
    let playURL: String
    /// Indicates the playback session ID.
    let sid: String
    /// Indicates the zone prefix (e.g., https://content-ause2.uplynk.com/) for the viewer's session. Use this prefix when submitting playback or API requests (e.g., Ping endpoint) for this session.
    let prefix: String
    /// Contains ad information, such as break offsets and non-video ads.
    let ads: UplynkAds
    /// The response may include this object when Studio DRM has been activated on your account.
    let drm: PrePlayDRMConfiguration?
    /// Indicates the URL to the XML file containing interstitial information for Apple TV. This parameter reports null when ads are not found.
    let interstitialURL: String?
}

