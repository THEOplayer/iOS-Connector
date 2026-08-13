//
//  AdHandler+THEOads.swift
//

import ConvivaSDK
import THEOplayerSDK

#if canImport(THEOplayerTHEOadsIntegration)
import THEOplayerTHEOadsIntegration

extension AdHandler {
    /// A THEOads (SGAI) ad break can fail before any ad is available, for example when the ad server
    /// returns an empty VAST response. No ad break or ad events are dispatched in that case, so report
    /// the attempted ad break as a failed ad to keep Conviva's ad attempt and fill rate metrics correct.
    func interstitialError(event: THEOplayerTHEOadsIntegration.InterstitialErrorEvent) {
        let interstitial = event.interstitial
        guard interstitial.type == .adbreak else { return }
        self.reportFailedAdBreak(
            message: event.message ?? "No ad available",
            podDuration: interstitial.duration,
            podPosition: Self.calculateInterstitialAdBreakPosition(startTime: interstitial.startTime)
        )
    }

    /// The position of a THEOads interstitial based on its start time.
    static func calculateInterstitialAdBreakPosition(startTime: Double) -> String {
        if startTime == 0 {
            return "Pre-roll"
        } else if startTime < 0 || !startTime.isFinite {
            return "Post-roll"
        } else {
            return "Mid-roll"
        }
    }
}
#endif
