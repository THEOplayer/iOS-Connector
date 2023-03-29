//
//  ComscoreConfig.swift
//  ComscoreReporter
//
//  Created by Wonne Joosen on 10/03/2023.
//

import THEOplayerConnectorComscore
import THEOplayerSDK

private func extractCUSV(ad: THEOplayerSDK.Ad) -> String {
    var extractedAdId: String
    let googleImaAd = ad as! GoogleImaAd
    if (googleImaAd.adSystem == "GDFP" ) {
        extractedAdId = googleImaAd.creativeId!
    } else {
        extractedAdId = "-1"
        let uids = googleImaAd.universalAdIds
        let pattern = #"([a-z]{6}\w{7}[a-z])"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        for uid in uids {
            let uidvalue = uid.adIdValue
            if let match = regex?.firstMatch(in: uidvalue, options: [], range: NSRange(location: 0, length: uidvalue.utf16.count)) {
                for i in 1..<match.numberOfRanges {
                    if let statusCodeRange = Range(match.range(at: i), in: uidvalue) {
                        print("CUSV found", uidvalue[statusCodeRange])
                        extractedAdId = String(uidvalue[statusCodeRange])
                        return extractedAdId
                    }
                }
                extractedAdId = "-2"
                return extractedAdId
            }
        }
    }
    return extractedAdId
}

let comscoreConfig = ComScoreConfiguration(
    publisherId: "put your publisher id here",
    applicationName: "put your application name here",
    userConsent: .granted,
    adIdProcessor: nil,
    debug: true
)
