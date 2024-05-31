//
//  DefaultPlaybackPolicy.swift
//
//  Created by Raffi on 30/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation
import YOAdManagement

class DefaultPlaybackPolicy: NSObject, YOPlaybackPolicyHandling {
    var playbackMode: YOPlaybackMode

    init(playbackMode: YOPlaybackMode) {
        self.playbackMode = playbackMode
        super.init()
    }

    func canStop(_ playhead: TimeInterval, timeline: [Any]) -> Bool {
        return true
    }

    func canPause(_ playhead: TimeInterval, timeline: [Any]) -> Bool {
        return true
    }

    func canSkip(_ playhead: TimeInterval, timeline: [Any], duration: TimeInterval) -> TimeInterval {
        if self.playbackMode == .YOLiveMode {
            // skipping an advert is not possible in Live playback
            return -1.0
        } else {
            guard let ad: YOAdvert = self.isInAdvert(playhead, timeline: timeline) else {
                // cannot skip if not in advert
                return -1.0
            }

            var skipOffset: TimeInterval = ad.skipOffset

            if skipOffset == -1.0 {
                return skipOffset
            }

            if !ad.isActive {
                // can skip an inactive advert
                skipOffset = 0
            } else if skipOffset >= 0 {
                // calculate the difference between offset and playhead, unless negative.
                skipOffset = max(0, ad.start + skipOffset - playhead)
            }

            return skipOffset
        }
    }

    // This adapter implements a 'right to watch' policy for non-linear streams, which means that if a user attempts to seek past
    // an active break, this method returns the start position of that break. In this case the client should honour seeking to
    // that position.
    // If the user scrubs over multiple active breaks then this method returns the start position of the closest active
    // break - the user is obliged to watch only the ad break immediately prior to the content they have tried to scrub to.
    // In this case the client MUST call didSeekFrom:to:timeline:, which in this implemetation disables the ad breaks that were
    // sought through and are still active.
    // Once a break is watched through to completion, it is set as 'inactive' by the SDK, which means that it can be freely scrubbed through.
    func willSeek(to position: TimeInterval, timeline: [Any], playhead: TimeInterval) -> TimeInterval {
        if self.playbackMode == .YOLiveMode {
            return playhead
        }

        // if in an ad break, the current playhead will be returned
        var actual: TimeInterval = playhead
        var br: YOAdBreak? = self.isInActiveBreak(playhead, timeline: timeline)

        if br == nil {
            // not in an ad break: find the closest active ad break prior to the current playhead if there is one
            br = self.closestBreakPriorTo(position, timeline: timeline)
            if br != nil {
                // return the closest active break start
                actual = br!.start
            } else {
                // return the requested position
                actual = position
            }
        }

        return actual
    }

    func canChangeVolume(_ mute: Bool, playhead: TimeInterval, timeline: [Any]) -> Bool {
        return true
    }

    func canResize(_ fullscreen: Bool, playhead: TimeInterval, timeline: [Any]) -> Bool {
        return true
    }

    func canResizeCreative(_ expand: Bool, playhead: TimeInterval, timeline: [Any]) -> Bool {
        return true
    }

    func canClickThrough(_ url: URL, playhead: TimeInterval, timeline: [Any]) -> Bool {
        return true
    }

    func setPlaybackMode(_ playbackMode: YOPlaybackMode) {
        self.playbackMode = playbackMode
    }

    func didSkip(from previous: TimeInterval, to current: TimeInterval, timeline: [Any]) {
        self.didSeek(from: previous, to: current, timeline: timeline)
    }

    func didSeek(from previous: TimeInterval, to current: TimeInterval, timeline: [Any]) {
        if self.playbackMode != .YOLiveMode && (previous < current) {
            self.setInactiveAllAdBreaksBetween(previous, and: current, timeline: timeline)
        }
    }

    private func isInAdvert(_ playhead: TimeInterval, timeline: [Any]) -> YOAdvert? {
        guard let adBreaks: [YOAdBreak] = timeline as? [YOAdBreak] else {
            return nil
        }

        for adBreak in adBreaks {
            if self.compare(adBreak.start, lessThanOrEqualTo: playhead) && playhead < (adBreak.start + adBreak.duration) {
                for ad in adBreak.adverts {
                    if let yospaceAd: YOAdvert = ad as? YOAdvert,
                       self.compare(yospaceAd.start, lessThanOrEqualTo: playhead) && playhead < (yospaceAd.start + yospaceAd.duration) {
                        return yospaceAd
                    }
                }
            }
        }

        return nil
    }

    private func isInActiveBreak(_ playhead: TimeInterval, timeline: [Any]) -> YOAdBreak? {
        guard let adBreaks: [YOAdBreak] = timeline as? [YOAdBreak] else {
            return nil
        }

        for adBreak in adBreaks {
            if self.compare(adBreak.start, lessThanOrEqualTo: playhead) && playhead < (adBreak.start + adBreak.duration) {
                return adBreak.isActive() ? adBreak : nil
            }
        }

        return nil
    }

    private func closestBreakPriorTo(_ position: TimeInterval, timeline: [Any]) -> YOAdBreak? {
        guard let adBreaks: [YOAdBreak] = timeline as? [YOAdBreak] else {
            return nil
        }

        var closest: YOAdBreak?
        for adBreak in adBreaks {
            if adBreak.start < position && adBreak.isActive() {
                closest = adBreak
            }
        }

        return closest
    }

    private func setInactiveAllAdBreaksBetween(_ start: TimeInterval, and end: TimeInterval, timeline: [Any]) {
        guard let adBreaks: [YOAdBreak] = timeline as? [YOAdBreak] else {
            return
        }

        for adBreak in adBreaks {
            if adBreak.isActive() && (adBreak.start >= start) && (adBreak.start + adBreak.duration) <= end {
                adBreak.setInactive()
            }
        }
    }

    private func compare(_ first: TimeInterval, lessThanOrEqualTo second: TimeInterval) -> Bool {
        if first < second {
            return true
        }

        return (fabs(first - second) < 0.001)
    }
}
