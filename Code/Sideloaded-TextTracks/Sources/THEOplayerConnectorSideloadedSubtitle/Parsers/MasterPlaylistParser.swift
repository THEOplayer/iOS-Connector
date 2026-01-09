//
//  MasterPlaylistParser.swift
//  THEOplayer_SDK
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation
import THEOplayerSDK

class MasterPlaylistParser: PlaylistParser {
    var constructedManifestArray = [String]()
    fileprivate var lastMediaLine: Int?
    fileprivate let subtitlesGroupId = "THEOsubs"

    override init(url: URL) {
        super.init(url: url)
    }
    
    func sideLoadSubtitles(subtitles: [TextTrackDescription]) async -> Data? {
        guard let _ = await self.loadManifest() else { return nil }
        self.parseManifest()
        self.appendSubtitlesLines(subtitles: subtitles)
        let constructed = self.constructedManifestArray.joined(separator: "\n")
        if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
            print("[AVSubtitlesLoader] MASTER: +++++++")
            print(constructed)
            print("[AVSubtitlesLoader] MASTER: ------")
        }
        return constructed.data(using: .utf8)
    }
    
    fileprivate func parseManifest() {
        guard let manifestData = self.manifestData, let manifestString = String(data: manifestData, encoding: .utf8) else {
            #if DEBUG
            print("ERROR parsing the Master playlist")
            #endif
            return
        }
        let allLines = manifestString.components(separatedBy: "\n")
        var iterator = allLines.makeIterator()
        while let lineString = iterator.next()?.trimmingCharacters(in: .whitespacesAndNewlines) {
            let line = HLSLine(lineString: lineString)
            // we need this to force-use the absoluteURL in any URI parameter in a line
            // the reason for this behaviour is that AVPlayer will use the custom Scheme if relativeURL is provided
            self.updateRelativeUri(line: line)
            
            switch line.tag {
            case ManifestTags.ExtXMedia.rawValue:
                if let type = line.paramsObject[HLSKeywords.type.rawValue] {
                    switch type {
                    case HLSKeywords.subtitles.rawValue:
                        line.paramsObject[HLSKeywords.groupId.rawValue] = "\"\(self.subtitlesGroupId)\""
                        self.lastMediaLine = self.constructedManifestArray.count

                    default:
                        break
                    }
                }
                self.constructedManifestArray.append(line.joinLine())
                
            case ManifestTags.ExtXStreamInf.rawValue:
                line.paramsObject[HLSKeywords.subtitles.rawValue] = "\"\(self.subtitlesGroupId)\""
                self.constructedManifestArray.append(line.joinLine())
                if let nextLine = iterator.next()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    let variantURL = self.getVariantURLWithCustomScheme(from: nextLine)
                    self.constructedManifestArray.append(variantURL)
                }
                
            default:
                self.constructedManifestArray.append(line.joinLine())
            }
        }
    }
    
    func appendSubtitlesLines(subtitles: [TextTrackDescription]) {
        for subtitle in subtitles {
            if let label = subtitle.label, let encodedURLString = subtitle.src.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                let defaultValue = subtitle.isDefault == true ? "YES" : "NO"
                let subtitleLine = "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"\(self.subtitlesGroupId)\",NAME=\"\(label)\",DEFAULT=\(defaultValue),URI=\"\(encodedURLString)\",LANGUAGE=\"\(subtitle.srclang)\""
                if let linePosition = self.lastMediaLine {
                    self.constructedManifestArray.insert("\(subtitleLine)", at: linePosition)
                } else {
                    self.constructedManifestArray.append("\(subtitleLine)")
                }
            }
        }
    }
    
    func getVariantURLWithCustomScheme(from path: String) -> String {
        guard let variantURL = self.getFullURL(from: path) else {
            return path.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return variantURL.absoluteString
    }
}
