//
//  AppEventForwarder.swift
//  
//
//  Created by Damiaan Dufaux on 27/09/2022.
//

import UIKit

fileprivate let willEnterForeground = UIApplication.willEnterForegroundNotification
fileprivate let didEnterBackground = UIApplication.didEnterBackgroundNotification

class AppEventForwarder {
    let center = NotificationCenter.default
    let foregroundObserver, backgroundObserver: Any
    
    init(eventProcessor: AppEventProcessor) {
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
    }
    
    deinit {
        center.removeObserver(foregroundObserver, name: willEnterForeground, object: nil)
        center.removeObserver(backgroundObserver, name: didEnterBackground, object: nil)
    }
}

protocol AppEventProcessor {
    func appWillEnterForeground(notification: Notification)
    func appDidEnterBackground(notification: Notification)
}
