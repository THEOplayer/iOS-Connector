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
        print("Conviva reporting foreground")
        analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        print("Conviva reporting background")
        analytics.reportAppBackgrounded()
    }
}
