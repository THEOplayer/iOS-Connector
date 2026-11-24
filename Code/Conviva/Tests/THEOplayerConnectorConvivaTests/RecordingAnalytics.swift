//
//  RecordingAnalytics.swift
//

import ConvivaSDK

/// Records the calls the connector makes on the Conviva SDK so tests can assert on what is reported.
class RecordingStreamAnalytics: NSObject, CISStreamAnalyticsProtocol {
    private(set) var metrics: [(key: String, value: Any?)] = []
    private(set) var cleanupCount = 0

    func metricValues(_ key: String) -> [Any?] {
        metrics.filter { $0.key == key }.map(\.value)
    }

    var playerStates: [PlayerState] {
        metricValues(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE).compactMap { ($0 as? UInt).flatMap(PlayerState.init(rawValue:)) }
    }

    func reportPlaybackMetric(_ key: String, value: Any?) { metrics.append((key, value)) }
    func cleanup() { cleanupCount += 1 }
    func report(_ playerState: PlayerState) {}
    func getSessionId() -> Int32 { 42 }
    func getSessionKey() -> Int32 { 42 }
    func getMetadataInfo() -> [AnyHashable: Any] { [:] }
    func setUpdateHandler(_ updateHandler: @escaping UpdateHandler) {}
    func isAdAnalytics() -> Bool { false }
    func isVideoAnalytics() -> Bool { false }
    func isAirPlaying() -> Bool { false }
}

final class RecordingVideoAnalytics: RecordingStreamAnalytics, CISVideoAnalyticsProtocol {
    private(set) var contentInfos: [[AnyHashable: Any]] = []
    private(set) var playbackRequested: [[AnyHashable: Any]?] = []
    /// Number of recorded metrics at each `reportPlaybackRequested` call, to check what was reported after a session started.
    private(set) var metricCountAtPlaybackRequested: [Int] = []
    private(set) var playbackEndedCount = 0
    private(set) var playbackFailed: [String] = []
    private(set) var playbackErrors: [(message: String, severity: ErrorSeverity)] = []
    private(set) var adBreaksStarted: [(adType: AdTechnology, info: [AnyHashable: Any])] = []
    private(set) var adBreakEndedCount = 0

    /// Content info values for `key`, in the order they were sent.
    func contentInfoValues(_ key: String) -> [Any] {
        contentInfos.compactMap { $0[key] }
    }

    func setContentInfo(_ contentInfo: [AnyHashable: Any]) { contentInfos.append(contentInfo) }
    func reportPlaybackRequested(_ contentInfo: [AnyHashable: Any]?) {
        playbackRequested.append(contentInfo)
        metricCountAtPlaybackRequested.append(metrics.count)
    }
    func reportPlaybackEnded() { playbackEndedCount += 1 }
    func reportPlaybackFailed(_ errorMessage: String, contentInfo: [AnyHashable: Any]?) { playbackFailed.append(errorMessage) }
    func reportPlaybackError(_ errorMessage: String, errorSeverity severity: ErrorSeverity) { playbackErrors.append((errorMessage, severity)) }
    func reportAdBreakStarted(_ adPlayer: AdPlayer, adType: AdTechnology, adBreakInfo: [AnyHashable: Any]) { adBreaksStarted.append((adType, adBreakInfo)) }
    func reportAdBreakEnded() { adBreakEndedCount += 1 }
    func setPlayerInfo(_ playerInfo: [AnyHashable: Any]) {}
    func reportPlaybackEvent(_ eventName: String, withAttributes attributes: [AnyHashable: Any]?) {}
    func setPlayer(_ player: Any?) {}
    func setAdAnalytics(_ adAnalytics: CISAdAnalytics) {}
}

final class RecordingAdAnalytics: RecordingStreamAnalytics, CISAdAnalyticsProtocol {
    private(set) var adInfos: [[AnyHashable: Any]] = []
    private(set) var adFailed: [(message: String, adInfo: [AnyHashable: Any]?)] = []

    func setAdInfo(_ adInfo: [AnyHashable: Any]) { adInfos.append(adInfo) }
    func reportAdFailed(_ errorMessage: String, adInfo: [AnyHashable: Any]?) { adFailed.append((errorMessage, adInfo)) }
    func reportAdLoaded(_ adInfo: [AnyHashable: Any]?) {}
    func reportAdStarted(_ adInfo: [AnyHashable: Any]?) {}
    func reportAdEnded() {}
    func setAdPlayerInfo(_ adPlayerInfo: [AnyHashable: Any]) {}
    func reportAdError(_ errorMessage: String, severity: ErrorSeverity) {}
    func reportAdSkipped() {}
    func reportAdPlayerEvent(_ eventType: String, details: [AnyHashable: Any]?) {}
    func reportAdMetric(_ key: String, value: Any) {}
    func setContentSessionID(_ sessionID: Int32) {}
    func setAdListener(_ adProxy: Any?, andInfo info: [AnyHashable: Any]) {}
}

final class RecordingAnalytics: NSObject, CISAnalyticsProtocol {
    let video = RecordingVideoAnalytics()
    let ad = RecordingAdAnalytics()

    func createVideoAnalytics() -> CISVideoAnalytics { video }
    func createVideoAnalytics(_ options: [AnyHashable: Any]) -> CISVideoAnalytics { video }
    func createAdAnalytics() -> CISAdAnalytics { ad }
    func createAdAnalytics(withVideoAnalytics videoAnalytics: CISVideoAnalytics) -> CISAdAnalytics { ad }
    func getClientId() -> String { "test-client" }
    func reportAppEvent(_ event: String, details: [AnyHashable: Any]) {}
    func reportAppBackgrounded() {}
    func reportAppForegrounded() {}
    func setUserPrefsForDataCollection(_ userPrefs: [AnyHashable: Any]) {}
    func setUserPrefsForDataDeletion(_ userPrefs: [AnyHashable: Any]) {}
    func cleanup() {}
    func getGlobalSessionId() -> Int32 { 0 }
    func getipv4SessionId() -> Int32 { 0 }
    func getipv6SessionId() -> Int32 { 0 }
}
