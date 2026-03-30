//
//  AppEventForwarder.swift
//  

import UIKit
import THEOplayerSDK
import AVFoundation
import THEOplayerConnectorUtilities

fileprivate let willEnterForeground = UIApplication.willEnterForegroundNotification
fileprivate let didEnterBackground = UIApplication.didEnterBackgroundNotification

class AppEventForwarder {
    private let center = NotificationCenter.default
    private let foregroundObserver, backgroundObserver: Any
    
    init(handler: AppHandler) {
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
