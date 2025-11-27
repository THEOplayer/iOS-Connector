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
    private var extXMediaSubtitlesOriginallyExists = false

    override init(url: URL) {
        super.init(url: url)
    }
    
    func sideLoadSubtitles(subtitles: [TextTrackDescription], completion: @escaping (_ data: Data?) -> ()) {
        self.loadManifest { succ in
            if succ {
                let validSubtitles = subtitles.filter { subtitle in
                    guard subtitle.src.isValid == true else {
                        print("The provided subtitle source \(subtitle.src.absoluteString) is invalid")
                        return false
                    }
                    return true
                }
                self.parseManifest()
                self.appendSubtitlesLines(subtitles: validSubtitles)
                if !self.extXMediaSubtitlesOriginallyExists,
                   validSubtitles.isEmpty {
                    // when the original m3u8 does not have any subtitles, and there are no valid subtitles to sideload
                    // then we remove the added subs attribute from the ExtXStreamInf entries
                    for (i, ele) in self.constructedManifestArray.enumerated() {
                        let line = HLSLine(lineString: ele)
                        line.paramsObject.removeValue(forKey: HLSKeywords.subtitles.rawValue)
                        self.constructedManifestArray[i] = line.joinLine()
                    }
                }
                let constructed = self.constructedManifestArray.joined(separator: "\n")
                
                if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
                    print("[AVSubtitlesLoader] MASTER: +++++++")
                    print(constructed)
                    print("[AVSubtitlesLoader] MASTER: ------")
                }
                
                completion(constructed.data(using: .utf8))
            } else {
                completion(nil)
            }
        }
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
                        self.extXMediaSubtitlesOriginallyExists = true
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
                let subtitleCustomSchemePath = encodedURLString.byConcatenatingScheme(scheme: URLScheme.subtitlesm3u8)
                let subtitleLine = "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"\(self.subtitlesGroupId)\",NAME=\"\(label)\",URI=\"\(subtitleCustomSchemePath)\",LANGUAGE=\"\(subtitle.srclang)\""
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
        return variantURL.absoluteString.byConcatenatingScheme(scheme: URLScheme.variantm3u8) 
    }
}
