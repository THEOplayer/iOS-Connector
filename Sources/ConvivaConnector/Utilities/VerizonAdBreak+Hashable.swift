//
//  AdBreak+Hashable.swift
//  TheoConvivaConnector
//
//  Created by Damiaan Dufaux on 28/09/2022.
//

#if VERIZONMEDIA
import THEOplayerSDK

extension VerizonMediaAdBreak {
    var asHashable: HashableVerizonMediaAdBreak { HashableVerizonMediaAdBreak(adBreak: self) }
}

struct HashableVerizonMediaAdBreak: Swift.Hashable {
    let adBreak: VerizonMediaAdBreak
    
    static func == (lhs: HashableVerizonMediaAdBreak, rhs: HashableVerizonMediaAdBreak) -> Bool {
        lhs.adBreak.isEqual(rhs.adBreak)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(adBreak.hash)
    }
}
#endif
