//
//  PreplayResponse.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

struct PrePlayDRMConfiguration: Codable {
    let required: Bool
    let fairplayCertificateURL: String?
}

struct PreplayResponse: Codable {
    let playURL: String
    let drm: PrePlayDRMConfiguration?
}
