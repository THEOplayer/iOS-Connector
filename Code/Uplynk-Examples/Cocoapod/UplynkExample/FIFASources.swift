//
//  File.swift
//  UplynkExample
//
//  Created by Raveendran, Aravind on 7/2/2025.
//

import Foundation
import THEOplayerConnectorUplynk

struct FIFASource {
    let url: URL
    let assetID: String
    let externalID: String?
    let tokenRequired: Bool
}

extension FIFASource {
    
    // Token required
    static let source1 = FIFASource(url: URL(string: "https://content.uplynk.com/player5/3D0PYRlstKHws59xA190jfsa.html")!,
                                    assetID: "a96defe30d7543c2bc52097ceb224384",
                                    externalID: "0x3lzrXaqky_t3qwa9F66w",
                                    tokenRequired: true)
    
    static let source2 = FIFASource(url: URL(string: "https://content.uplynk.com/player5/9cEt0pA4TRvcbBqZyQrgJsa.html")!,
                                    assetID: "d4df519c558341748ad0b36e5f67f906",
                                    externalID: "QWhv8yi7M0ywkwKW2ehaCA",
                                    tokenRequired: true)
    
    static let source3 = FIFASource(url: URL(string: "https://content.uplynk.com/player5/wGiZcf4hmYRbbrNwfj1Nksa.html")!,
                                    assetID: "e3a379ba6ac04bc897af37fe94db6321",
                                    externalID: "ux4ELy_Kuk2UldEDJVjI6w",
                                    tokenRequired: true)
    
    // Token required + ads
    static let source4 = FIFASource(url: URL(string: "https://content.uplynk.com/player5/61VhTlJSFS8n48FVANrHzJsa.html")!,
                                    assetID: "acdbbc618564ae7a6748f23af6f7a3c",
                                    externalID: nil,
                                    tokenRequired: true)
    
    // Token is not required
    static let source5 = FIFASource(url: URL(string: "https://content.uplynk.com/player5/1W8JSQrGnsk7YtzALXCUPzsa.html")!,
                                    assetID: "e86b14f27785468f97c46cf3ef162164",
                                    externalID: nil,
                                    tokenRequired: false)
}
