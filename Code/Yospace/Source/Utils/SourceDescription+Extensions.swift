//
//  SourceDescription+Extensions.swift
//
//  Created by Raffi on 30/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

extension THEOplayerSDK.SourceDescription {
    func createCopy() -> THEOplayerSDK.SourceDescription {
        return THEOplayerSDK.SourceDescription(sources: self.sources, textTracks: self.textTracks, ads: self.ads, poster: self.poster?.absoluteString, metadata: self.metadata)
    }
}
