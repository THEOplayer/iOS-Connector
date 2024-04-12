//
//  VariantPlaylistParser.swift
//  THEOplayer_SDK
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation

class VariantPlaylistParser: PlaylistParser {
    fileprivate(set) var totalPlayListDuration: Double
    var constructedManifestArray = [String]()
    
    override init(url: URL) {
        self.totalPlayListDuration = 0
        super.init(url: url)
    }
    
    func parse(completion: @escaping (_ playlist: VariantPlaylistParser?) -> ()) {
        self.loadManifest { succ in
            if succ {
                self.parseManifest()
                let constructed = self.constructedManifestArray.joined(separator: "\n")
                
                if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
                    print("[AVSubtitlesLoader] VARIANT: +++++++")
                    print(constructed)
                    print("[AVSubtitlesLoader] VARIANT: ------")
                }
                
                if let data = constructed.data(using: .utf8) {
                    self.manifestData = data
                }
                completion(self)
            } else {
                completion(nil)
            }
        }
    }
    
    fileprivate func parseManifest() {
        guard let manifestData = self.manifestData, let manifestString = String(data: manifestData, encoding: .utf8) else {
            #if DEBUG
            print("[AVSubtitlesLoader] ERROR parsing the variant playlist")
            #endif
            return
        }
        let allLines = manifestString.components(separatedBy: "\n")
        var iterator = allLines.makeIterator()
        
        while let lineString = iterator.next()?.trimmingCharacters(in: .whitespacesAndNewlines).removingPercentEncoding {
            let line = HLSLine(lineString: lineString)
            // we need this to force-use the absoluteURL in any URI parameter in a line
            // the reason for this behaviour is that AVPlayer will use the custom Scheme if relativeURL is provided
            self.updateRelativeUri(line: line)

            switch line.tag {
            case ManifestTags.ExtInf.rawValue:
                guard let duration = Double(lineString.filter("0123456789.".contains)) else {
                    return
                }
                self.totalPlayListDuration += duration
                self.constructedManifestArray.append(line.joinLine())
                if let nextLine = iterator.next()?.trimmingCharacters(in: .whitespacesAndNewlines).removingPercentEncoding {
                    if nextLine.hasPrefix("#EXT-X-BYTERANGE") {
                        self.constructedManifestArray.append(nextLine)
                        if let segmentLine = iterator.next()?.trimmingCharacters(in: .whitespacesAndNewlines).removingPercentEncoding {
                            if let fullURL = self.getFullURL(from: segmentLine) {
                                self.constructedManifestArray.append(fullURL.absoluteString)
                            }
                        }
                    } else if let fullURL = self.getFullURL(from: nextLine) {
                        self.constructedManifestArray.append(fullURL.absoluteString)
                    }
                }
            default:
                self.constructedManifestArray.append(line.joinLine())
            }
        }
    }
}
