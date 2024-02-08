//
//  AppEventForwarder.swift
//  
//
//  Created by Damiaan Dufaux on 27/09/2022.
//

import UIKit
import THEOplayerSDK
import AVFoundation

fileprivate let willEnterForeground = UIApplication.willEnterForegroundNotification
fileprivate let didEnterBackground = UIApplication.didEnterBackgroundNotification

#if swift(>=5.9)
fileprivate let accessLogNotificationName = AVPlayerItem.newAccessLogEntryNotification
#else
fileprivate let accessLogNotificationName = NSNotification.Name.AVPlayerItemNewAccessLogEntry
#endif

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
            forName: accessLogNotificationName,
            object: .none,
            queue: .none,
            using: { [unowned player] notification in
                guard let item = notification.object as? AVPlayerItem else {return}
                guard let event = item.accessLog()?.events.last else {return}
                guard item == player.currentItem else { return } // TODO: Remove this.
                
                eventProcessor.appGotNewAccessLogEntry(event: event, isPlayingAd: player.ads.playing)
            })
    }
    
    deinit {
        center.removeObserver(foregroundObserver, name: willEnterForeground, object: nil)
        center.removeObserver(backgroundObserver, name: didEnterBackground, object: nil)
        center.removeObserver(accessLogObserver, name: accessLogNotificationName, object: nil)
    }
}

protocol AppEventProcessor {
    func appWillEnterForeground(notification: Notification)
    func appDidEnterBackground(notification: Notification)
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent, isPlayingAd: Bool)
}
