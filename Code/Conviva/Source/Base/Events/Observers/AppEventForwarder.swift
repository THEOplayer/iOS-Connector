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
fileprivate let newAccessLogEntry = Notification.Name("AVPlayerItemNewAccessLogEntry")

class AppEventForwarder {
    private let center = NotificationCenter.default
    private let foregroundObserver, backgroundObserver, accessLogObserver: Any
    private let adsLoadedEventListener: RemovableEventListenerProtocol?
    private let adsEndEventListener: RemovableEventListenerProtocol?
    private let sourceChangeEventListener: RemovableEventListenerProtocol?
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
        
        self.accessLogObserver = center.addObserver( // TODO: implement this in THEOplayerSDK using an observer on the correct player item so we can remove src URL checks
            forName: newAccessLogEntry,
            object: .none,
            queue: OperationQueue.main,
            using: { [unowned player] notification in
                guard let item = notification.object as? AVPlayerItem else {return}
                guard let event = item.accessLog()?.events.last else {return}
                guard item == player.currentItem else { return } // TODO: Remove this.

                // BUGFIX: There is a case where we get the ad bitrate reported as a new log entry
                handler.appGotNewAccessLogEntry(event: event, item: item, isPlayingAd: player.ads.playing)
            }
        )
        
        self.adsLoadedEventListener = player.ads.addRemovableEventListener(type: AdsEventTypes.AD_LOADED) { event in
            DispatchQueue.main.async {
                handler.adDidLoad(event: event)
            }
        }
        
        self.adsEndEventListener = player.ads.addRemovableEventListener(type: AdsEventTypes.AD_END) { event in
            DispatchQueue.main.async {
                handler.adDidEnd(event: event)
            }
        }
        
        self.sourceChangeEventListener = player.addRemovableEventListener(type: PlayerEventTypes.SOURCE_CHANGE) { event in
            DispatchQueue.main.async {
                handler.sourceChanged(event: event)
            }
        }
    }
    
    deinit {
        self.center.removeObserver(foregroundObserver, name: willEnterForeground, object: nil)
        self.center.removeObserver(backgroundObserver, name: didEnterBackground, object: nil)
        self.center.removeObserver(accessLogObserver, name: newAccessLogEntry, object: nil)
        if let player = self.player {
            self.adsLoadedEventListener?.remove(from: player.ads)
            self.adsEndEventListener?.remove(from: player.ads)
            self.sourceChangeEventListener?.remove(from: player)
        }
    }
}
