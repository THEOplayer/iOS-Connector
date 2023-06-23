//
//  File.swift
//  
//
//  Created by Damiaan Dufaux on 12/10/2022.
//

import ConvivaSDK

class ConvivaEndpoints {
    let analytics: CISAnalytics
    let videoAnalytics: CISVideoAnalytics
    let adAnalytics: CISAdAnalytics
    
    init?(configuration: ConvivaConfiguration) {
        guard let analytics = CISAnalyticsCreator.create(withCustomerKey: configuration.customerKey,
                                                         settings: configuration.convivaSettingsDictionary) else {
            return nil
        }
        
        self.analytics = analytics
        self.videoAnalytics = analytics.createVideoAnalytics()
        self.adAnalytics = analytics.createAdAnalytics(withVideoAnalytics: videoAnalytics)
        self.videoAnalytics.setPlayerInfo(Utilities.playerInfo)
    }
    
    func destroy() {
        self.adAnalytics.cleanup()
        self.videoAnalytics.cleanup()
        self.analytics.cleanup()
    }
}
