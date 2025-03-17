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
fileprivate let bitrateChangeEvent = Notification.Name("THEOliveBitrateChangeEvent")

class AppEventForwarder {
    let center = NotificationCenter.default
    let foregroundObserver, backgroundObserver, accessLogObserver, bitrateChangeObserver: Any
    let adsLoadedEventListener: RemovableEventListenerProtocol?
    let adsEndEventListener: RemovableEventListenerProtocol?
    let sourceChangeEventListener: RemovableEventListenerProtocol?

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
            queue: OperationQueue.main,
            using: { [unowned player] notification in
                guard let item = notification.object as? AVPlayerItem else {return}
                guard let event = item.accessLog()?.events.last else {return}
                guard item == player.currentItem else { return } // TODO: Remove this.

                // BUGFIX: There is a case where we get the ad bitrate reported as a new log entry
                eventProcessor.appGotNewAccessLogEntry(event: event, item: item, isPlayingAd: player.ads.playing)
            }
        )
        // Temporary workaround for THEOlive bitrate change events
        // TODO: Refactor this with active quality switch event dispatched from THEOplayer. This needs a videoTrack property exposed on THEOlive SDK which is currently missing.
        // NOTE: accessLogObserver can also be removed once the active quality switch event is implemented.
        bitrateChangeObserver = center.addObserver(
            forName: bitrateChangeEvent,
            object: .none,
            queue: .none,
            using: { notification in
                guard let userInfo = notification.userInfo else { return }
                guard let bitrate = userInfo["bitrate"] as? Double else { return }
                
                eventProcessor.appGotBitrateChangeEvent(bitrate: bitrate, isPlayingAd: player.ads.playing)
            }
        )
        
        
        adsLoadedEventListener = player.ads.addRemovableEventListener(
            type: AdsEventTypes.AD_LOADED
        ) { event in
            DispatchQueue.main.async {
                eventProcessor.adDidLoad(event: event)
            }
        }
        adsEndEventListener = player.ads.addRemovableEventListener(
            type: AdsEventTypes.AD_END
        ) { event in
            DispatchQueue.main.async {
                eventProcessor.adDidEnd(event: event)
            }
        }
        
        sourceChangeEventListener = player.addRemovableEventListener(
            type: PlayerEventTypes.SOURCE_CHANGE
        ) { event in
            DispatchQueue.main.async {
                eventProcessor.sourceChanged(event: event)
            }
        }
    }
    
    deinit {
        center.removeObserver(foregroundObserver, name: willEnterForeground, object: nil)
        center.removeObserver(backgroundObserver, name: didEnterBackground, object: nil)
        center.removeObserver(accessLogObserver, name: newAccessLogEntry, object: nil)
        center.removeObserver(accessLogObserver, name: bitrateChangeEvent, object: nil)
        adsLoadedEventListener?.remove(from: player.ads)
        adsEndEventListener?.remove(from: player.ads)
        sourceChangeEventListener?.remove(from: player)

    }
}

protocol AppEventProcessor {
    // Workaround for THEOSD-14780
    func adDidLoad(event: AdLoadedEvent)
    func adDidEnd(event: AdEndEvent)
    func sourceChanged(event: SourceChangeEvent)
    func appWillEnterForeground(notification: Notification)
    func appDidEnterBackground(notification: Notification)
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent, item: AVPlayerItem, isPlayingAd: Bool)
    func appGotBitrateChangeEvent(bitrate: Double, isPlayingAd: Bool)
}
