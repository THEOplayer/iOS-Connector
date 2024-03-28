//
//  AppEventForwarder.swift
//  

import UIKit
import THEOplayerSDK
import AVFoundation

fileprivate let willEnterForeground = UIApplication.willEnterForegroundNotification
fileprivate let didEnterBackground = UIApplication.didEnterBackgroundNotification
// Xcode 15 (Swift 5.9) introduces (and only fires notification with) `AVPlayerItem.newAccessLogEntryNotification`, and deprecates `Notification.Name.AVPlayerItemNewAccessLogEntry` (doesn't fire notification anymore)
// Older Xcode and Swift versions only fire notification with `Notification.Name.AVPlayerItemNewAccessLogEntry`
// Both `AVPlayerItem.newAccessLogEntryNotification` and `Notification.Name.AVPlayerItemNewAccessLogEntry` are mapped to `Notification.Name("AVPlayerItemNewAccessLogEntry")`, hence we use that.
// Once we drop support for older versions (below Xcode 15 and Swift 5.9) we can switch from `Notification.Name("AVPlayerItemNewAccessLogEntry")` to `AVPlayerItem.newAccessLogEntryNotification`.
fileprivate let newAccessLogEntry = Notification.Name("AVPlayerItemNewAccessLogEntry")

class AppEventForwarder {
    let center = NotificationCenter.default
    let foregroundObserver, backgroundObserver, accessLogObserver: Any
    let player: THEOplayer
    
    init(player: THEOplayer, eventProcessor: AppEventProcessor) {
        self.player = player
        
        foregroundObserver = center.addObserver(
            forName: willEnterForeground,
            object: .none,
            queue: .none,
            using: eventProcessor.appWillEnterForeground
        )
        backgroundObserver = center.addObserver(
            forName: didEnterBackground,
            object: .none,
            queue: .none,
            using: eventProcessor.appDidEnterBackground
        )
        accessLogObserver = center.addObserver( // TODO: implement this in THEOplayerSDK using an observer on the correct player item so we can remove src URL checks
            forName: newAccessLogEntry,
            object: .none,
            queue: .none,
            using: { [unowned player] notification in
                guard let item = notification.object as? AVPlayerItem else {return}
                guard let event = item.accessLog()?.events.last else {return}
                guard item == player.currentItem else { return } // TODO: Remove this.

                eventProcessor.appGotNewAccessLogEntry(event: event, isPlayingAd: player.ads.playing)
            }
        )
    }
    
    deinit {
        center.removeObserver(foregroundObserver, name: willEnterForeground, object: nil)
        center.removeObserver(backgroundObserver, name: didEnterBackground, object: nil)
        center.removeObserver(accessLogObserver, name: newAccessLogEntry, object: nil)
    }
}

protocol AppEventProcessor {
    func appWillEnterForeground(notification: Notification)
    func appDidEnterBackground(notification: Notification)
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent, isPlayingAd: Bool)
}
