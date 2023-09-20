//
//  SourceValidator.swift
//
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation
import THEOplayerSDK

class SourceValidator {
    static func getValidTextTracks(_ source: SourceDescription) -> [TextTrackDescription]? {
        guard let sideLoadedTextTracks: [TextTrackDescription] = source.textTracks else {
            print("[AVSubtitlesLoader] Unable to find a valid TextTrackDescription for sideloading.")
            return nil
        }

        let filteredTextTracks = sideLoadedTextTracks.filter { $0.kind == .subtitles }
        if filteredTextTracks.isEmpty {
            print("[AVSubtitlesLoader] Unable to find a valid TextTrackDescription for sideloading.")
            return nil
        } else {
            return filteredTextTracks
        }
    }
}
