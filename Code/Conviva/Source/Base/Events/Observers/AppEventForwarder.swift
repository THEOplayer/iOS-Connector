//
//  AppEventForwarder.swift
//  

import UIKit
import THEOplayerSDK
import AVFoundation
import THEOplayerConnectorUtilities

fileprivate let willEnterForeground = UIApplication.willEnterForegroundNotification
fileprivate let didEnterBackground = UIApplication.didEnterBackgroundNotification
// Xcode 15 (Swift 5.9) introduces (and only fires notification with) `AVPlayerItem.newAccessLogEntryNotification`, and deprecates `Notification.Name.AVPlayerItemNewAccessLogEntry` (doesn't fire notification anymore)
// Older Xcode and Swift versions only fire notification with `Notification.Name.AVPlayerItemNewAccessLogEntry`
// Both `AVPlayerItem.newAccessLogEntryNotification` and `Notification.Name.AVPlayerItemNewAccessLogEntry` are mapped to `Notification.Name("AVPlayerItemNewAccessLogEntry")`, hence we use that.
// Once we drop support for older versions (below Xcode 15 and Swift 5.9) we can switch from `Notification.Name("AVPlayerItemNewAccessLogEntry")` to `AVPlayerItem.newAccessLogEntryNotification`.

class AppEventForwarder {
    private let center = NotificationCenter.default
    private let foregroundObserver, backgroundObserver: Any
    private weak var player: THEOplayer?
    
    init(player: THEOplayer, handler: AppHandler) {
        self.player = player
        
        self.foregroundObserver = center.addObserver(
            forName: willEnterForeground,
            object: .none,
            queue: .none,
            using: handler.appWillEnterForeground
        )
        
        self.backgroundObserver = center.addObserver(
            forName: didEnterBackground,
            object: .none,
            queue: .none,
            using: handler.appDidEnterBackground
        )
    }
    
    deinit {
        self.center.removeObserver(foregroundObserver, name: willEnterForeground, object: nil)
        self.center.removeObserver(backgroundObserver, name: didEnterBackground, object: nil)
    }
}
