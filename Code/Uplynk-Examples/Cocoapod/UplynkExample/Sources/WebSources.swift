//
//  WebSources.swift
//  UplynkExample
//
//  Created by Raveendran, Aravind on 7/2/2025.
//

import Foundation
import THEOplayerConnectorUplynk

struct WebSource {
    let url: URL
    let assetID: String
    let externalID: String?
    let userID: String?
    let tokenRequired: Bool
}

extension WebSource {
    
    // VOD sources:
    
    // Token required
    static let source1 = WebSource(url: URL(string: "https://content.uplynk.com/player5/3D0PYRlstKHws59xA190jfsa.html")!,
                                   assetID: "a96defe30d7543c2bc52097ceb224384",
                                   externalID: "0x3lzrXaqky_t3qwa9F66w",
                                   userID: "5d8e9ef63a204d0b8cb71b50093bde7d",
                                   tokenRequired: true)
    
    static let source2 = WebSource(url: URL(string: "https://content.uplynk.com/player5/9cEt0pA4TRvcbBqZyQrgJsa.html")!,
                                   assetID: "d4df519c558341748ad0b36e5f67f906",
                                   externalID: "QWhv8yi7M0ywkwKW2ehaCA",
                                   userID: "5d8e9ef63a204d0b8cb71b50093bde7d",
                                   tokenRequired: true)
    
    static let source3 = WebSource(url: URL(string: "https://content.uplynk.com/player5/wGiZcf4hmYRbbrNwfj1Nksa.html")!,
                                   assetID: "e3a379ba6ac04bc897af37fe94db6321",
                                   externalID: "ux4ELy_Kuk2UldEDJVjI6w",
                                   userID: "5d8e9ef63a204d0b8cb71b50093bde7d",
                                   tokenRequired: true)
    
    // Token required + ads
    static let source4 = WebSource(url: URL(string: "https://content.uplynk.com/player5/61VhTlJSFS8n48FVANrHzJsa.html")!,
                                   assetID: "4acdbbc618564ae7a6748f23af6f7a3c",
                                   externalID: nil,
                                   userID: nil,
                                   tokenRequired: true)
    
    // Token is not required
    static let source5 = WebSource(url: URL(string: "https://content.uplynk.com/player5/1W8JSQrGnsk7YtzALXCUPzsa.html")!,
                                   assetID: "e86b14f27785468f97c46cf3ef162164",
                                   externalID: nil,
                                   userID: nil,
                                   tokenRequired: false)
    
    // LIVE sources:
    static let source10 = WebSource(url: URL(string: "https://content.uplynk.com/player5/607exUNBJDf260nEJrrxtRsa.html")!,
                                    assetID: "cbf7d83f86d14a64b1df75386d5c4536",
                                    externalID: nil,
                                    userID: nil,
                                    tokenRequired: true)

}
