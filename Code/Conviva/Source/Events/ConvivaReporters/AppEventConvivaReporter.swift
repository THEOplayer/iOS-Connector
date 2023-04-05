//
//  AppStateConvivaReporter.swift
//  
//
//  Created by Damiaan Dufaux on 27/09/2022.
//

import ConvivaSDK

struct AppEventConvivaReporter: AppEventProcessor {
    let analytics: CISAnalytics
    
    func appWillEnterForeground(notification: Notification) {
        analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        analytics.reportAppBackgrounded()
    }
}
