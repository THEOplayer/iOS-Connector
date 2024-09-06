//
//  AdEventConvivaReporter.swift
//  
//
//  Created by Damiaan Dufaux on 07/09/2022.
//

import THEOplayerSDK
#if os(iOS)
import NielsenAppApi
#elseif os(tvOS)
import NielsenTVAppApi
#endif

public class AdEventReporter: AdEventProcessor {
    let nielsen: NielsenAppApi
        
    init(nielsen: NielsenAppApi) {
        self.nielsen = nielsen
    }
        
    public func adBegin(event: AdBeginEvent) {
        guard let ad = event.ad, event.ad?.type == THEOplayerSDK.AdType.linear else { return }
        nielsen.stop()
        nielsen.loadMetadata(
            [
                "type": ad.adBreak.nielsenType,
                "assetid": ad.id
            ]
        )
    }
    
    public func adEnd(event: AdEndEvent) {
        if event.ad?.type == THEOplayerSDK.AdType.linear {
            nielsen.stop()
        }
    }
}

extension AdBreak {
    var nielsenType: String {
        switch timeOffset {
        case 0   : return "preroll"
        case ..<0: return "postroll"
        default:   return "midroll"
        }
    }
}
