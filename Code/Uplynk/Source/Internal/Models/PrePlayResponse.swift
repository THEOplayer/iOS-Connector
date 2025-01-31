//
//  PreplayResponse.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

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
    let fw_parameters: Dictionary<String, String>?
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
    let ads: [UplynkLiveAd]?
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

