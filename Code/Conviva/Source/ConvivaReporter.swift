//
//  ConvivaReporter.swift
//  
//
//  Created on 22/06/2023.
//

import ConvivaSDK
import THEOplayerSDK

struct Session {
    struct Source {
        let description: SourceDescription
        let url: String?
    }
    var started = false
    var source: Source?
}

class ConvivaReporter {
    private let endPoints: ConvivaEndpoints
    private let storage = ConvivaStorage()
    private var currentSession = Session()
    private var inAdBreak: Bool = false
    
    init(endPoints: ConvivaEndpoints) {
        self.endPoints = endPoints
    }
    
    func destroy() {
        self.validatePlaybackEnded()
    }
    
    func reportViewerId(viewerID: String) {
        self.endPoints.videoAnalytics.setContentInfo([CIS_SSDK_METADATA_VIEWER_ID: viewerID])
    }
    
    func reportAssetName(assetName: String) {
        self.endPoints.videoAnalytics.setContentInfo([CIS_SSDK_METADATA_ASSET_NAME: assetName])
    }
    
    func reportPlay() {
        if !currentSession.started {
            self.endPoints.videoAnalytics.reportPlaybackRequested(nil)
            self.currentSession.started = true
        }
        if self.inAdBreak {
            self.endPoints.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
        }
    }
    
    func reportPlaying() {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
        if self.inAdBreak {
            self.endPoints.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
        }
    }
    
    func reportTimeUpdate(timeInMSec: NSNumber) {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: timeInMSec)
        if self.inAdBreak {
            self.endPoints.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: timeInMSec)
        }
    }
    
    func reportFrameRate(frameRate: NSNumber) {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE, value: frameRate)
        if self.inAdBreak {
            self.endPoints.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE, value: frameRate)
        }
    }
    
    func reportPause() {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
        if self.inAdBreak {
            self.endPoints.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
        }
    }
    
    func reportWaiting() {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_BUFFERING.rawValue)
    }
    
    func reportSeeking(timeInMSec: NSNumber) {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_STARTED, value: timeInMSec)
    }
    
    func reportSeeked(timeInMSec: NSNumber) {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_ENDED, value: timeInMSec)
    }
    
    func reportError(error: String) {
        self.endPoints.videoAnalytics.reportPlaybackFailed(error, contentInfo: nil)
    }
    
    func reportNetworkError(error: String) {
        self.endPoints.videoAnalytics.reportPlaybackError(error, errorSeverity: .ERROR_WARNING)
    }
    
    func reportSourceChange(sourceDescription: SourceDescription?, selectedUrl: String?) {
        if sourceDescription != currentSession.source?.description, currentSession.source != nil {
            self.validatePlaybackEnded()
        }
        
        // clear all stored values for the previous source
        self.storage.clear()
        
        let newSource: Session.Source?
        if let source = sourceDescription, let url = selectedUrl {
            newSource = .init(description: source, url: url)
            let contentInfo = [
                CIS_SSDK_METADATA_PLAYER_NAME: Utilities.playerFrameworkName,
                CIS_SSDK_METADATA_STREAM_URL: url,
                CIS_SSDK_METADATA_ASSET_NAME: source.metadata?.title ?? Utilities.defaultStringValue,
                CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: false),
                CIS_SSDK_METADATA_DURATION: NSNumber(value: -1)
            ] as [String: Any]
            self.endPoints.videoAnalytics.setContentInfo(contentInfo)
        } else {
            newSource = nil
            #if DEBUG
            print("[THEOplayerConnectorConviva] setting unknown source")
            #endif
        }
        self.currentSession.source = newSource
    }
    
    func reportEnded() {
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_STOPPED.rawValue)
        self.validatePlaybackEnded()
    }
    
    private func validatePlaybackEnded() {
        if self.currentSession.started {
            self.endPoints.videoAnalytics.reportPlaybackEnded()
            self.currentSession = Session()
        }
    }
    
    func reportDurationChange(duration: Double?) {
        if let newDuration = duration, self.currentSession.source?.url != nil {
            if newDuration.isInfinite {
                self.endPoints.videoAnalytics.setContentInfo([
                    CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: true)
                ])
            } else {
                self.endPoints.videoAnalytics.setContentInfo([
                    CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: false),
                    CIS_SSDK_METADATA_DURATION: NSNumber(value: newDuration)
                ])
            }
        }
    }
    
    func reportBitRate(kbps: NSNumber) {
        if inAdBreak {
            self.endPoints.adAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: kbps)
        } else {
            self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: kbps)
        }
        self.storage.storeKeyValuePair(key: CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: kbps)
    }
    
    func reportDroppedFrames(count: NSNumber) {
        if inAdBreak {
            self.endPoints.adAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL, value: count)
        } else {
            self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL, value: count)
        }
    }
    
    func reportDestroy() {
        self.validatePlaybackEnded()
    }
    
    func reportAppWillenterForeground() {
        self.endPoints.analytics.reportAppForegrounded()
    }
    
    func reportAppDidenterBackground() {
        self.endPoints.analytics.reportAppBackgrounded()
    }
    
    func reportAdBreakBegin(adBreak: AdBreak) {
        self.inAdBreak = true
        
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 6
        let adBreakPodDuration = NSNumber(value: adBreak.maxDuration)
        let adBreakPodIndex = NSNumber(value: adBreak.timeOffset)
        let adBreakPodPosition = NSNumber(value: adBreak.convivaAdPosition.rawValue)
        let adBreakPodDurationString = formatter.string(from: adBreakPodDuration) ?? adBreakPodDuration.description(withLocale: Utilities.en_usLocale)
        let adBreakPodIndexString = formatter.string(from: adBreakPodIndex) ?? adBreakPodIndex.description(withLocale: Utilities.en_usLocale)
        let adBreakPodPositionString = formatter.string(from: adBreakPodPosition) ?? adBreakPodPosition.description(withLocale: Utilities.en_usLocale)
        self.endPoints.videoAnalytics.reportAdBreakStarted(.ADPLAYER_CONTENT,
                                                           adType: .CLIENT_SIDE,
                                                           adBreakInfo: [
                                                            CIS_SSDK_AD_BREAK_POD_DURATION: adBreakPodDurationString,
                                                            CIS_SSDK_AD_BREAK_POD_INDEX: adBreakPodIndexString,
                                                            CIS_SSDK_AD_BREAK_POD_POSITION: adBreakPodPositionString])
    }
    
    func reportAdBreakEnd() {
        self.inAdBreak = false
        
        self.endPoints.videoAnalytics.reportAdBreakEnded()
    }
    
    func reportAdBegin(ad: Ad, duration: Double) {
        var info = ad.convivaInfo
        // Temporary workaround for missing LinearAd in Native THEOplayerGoogleIMAIntegration. Can be removed after THEO-10161 is completed.
        if !info.keys.contains(CIS_SSDK_METADATA_IS_LIVE) {
            if duration.isInfinite {
                info[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: true)
            } else {
                info[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: false)
                info[CIS_SSDK_METADATA_DURATION] = NSNumber(value: duration)
            }
        }
        self.endPoints.adAnalytics.reportAdLoaded(info)
        self.endPoints.adAnalytics.reportAdStarted(info)
        if let width = ad.width, let height = ad.height {
            self.endPoints.adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_RESOLUTION, value: NSValue(cgSize: .init(width: width, height: height)))
        }
    }
    
    func reportAdEnd() {
        self.endPoints.adAnalytics.reportAdEnded()
    }
    
    func reportAdError(error: String, info: [AnyHashable: Any]?) {
        self.endPoints.adAnalytics.reportAdFailed(error, adInfo: info)
    }
    
    func reportContentInfo(contentInfo: [String: Any]) {
        self.endPoints.videoAnalytics.setContentInfo(contentInfo)
    }
    
    func reportAdInfo(adInfo: [String: Any]) {
        self.endPoints.adAnalytics.setAdInfo(adInfo)
    }
    
    func reportStopAndStartNewSession(contentInfo: [String:Any]) {
        self.endPoints.videoAnalytics.reportPlaybackEnded()
        self.endPoints.videoAnalytics.reportPlaybackRequested(contentInfo)
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
        if let bitrate = self.storage.valueForKey(CIS_SSDK_PLAYBACK_METRIC_BITRATE) as? NSNumber {
            self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrate)
        }
    }
}
