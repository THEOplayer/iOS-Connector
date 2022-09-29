//
//  Plist.swift
//  
//
//  Created by Damiaan Dufaux on 29/09/2022.
//

struct TheoFrameworkPlist: Codable {
    let version: String
    let buildInfo: BuildInfo
    
    enum CodingKeys: String, CodingKey {
        case buildInfo = "THEOplayer build information"
        case version = "CFBundleShortVersionString"
    }
    
    struct BuildInfo: Codable {
        let features: String
        
        enum CodingKeys: String, CodingKey {
            case features = "Features"
        }
    }
}
