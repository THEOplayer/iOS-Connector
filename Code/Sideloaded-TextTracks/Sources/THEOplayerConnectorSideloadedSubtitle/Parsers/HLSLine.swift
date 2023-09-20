//
//  HLSLine.swift
//  THEOplayer_SDK
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation

enum ManifestTags: String, CaseIterable {
    case ExtM3U = "#EXTM3U"
    case ExtXStreamInf = "#EXT-X-STREAM-INF"
    case ExtInf = "#EXTINF"
    case ExtXMedia = "#EXT-X-MEDIA"
}

class HLSLine {
    fileprivate(set) var lineString: String
    var tag = String() // this value can either be the HLS TAG if the line is identified successfully, or the complete line if the identification fails
    var paramsString = String()
    var paramsObject = [String: String]()

    var uriParameter: String? {
        return self.paramsObject[PlaylistParser.HLSKeywords.uri.rawValue]?.replacingOccurrences(of: "\"", with: String())
    }

    init(lineString: String) {
        self.lineString = lineString
        self.parseLine(str: lineString)
    }
    
    fileprivate func parseLine(str: String) {
        switch str {
        case _ where str.starts(with: "#") && str.contains(":"):
            let components = str.components(separatedBy: ":")
            self.tag = components[0]
            self.paramsString = str.replacingOccurrences(of: "\(tag):", with: String())
            self.paramsObject = self.parseParamsForLine(line: self.paramsString)
            
        default:
            self.tag = str
            self.paramsString = String()
            self.paramsObject = [String: String]()
        }
    }
    
    fileprivate func parseParamsForLine(line: String) -> [String: String] {
        let allParams = line.split(regex: ",(?=([^\"]*\"[^\"]*\")*[^\"]*$)")
        var lineDic = [String: String]()
        allParams.forEach { str in
            let keyValue = str.components(separatedBy: "=")
            if keyValue.count >= 2 {
                let paramKey = keyValue[0].uppercased()
                let paramValue = str.replacingOccurrences(of: "\(paramKey)=", with: String())
                lineDic.updateValue(paramValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: paramKey)
            }
        }
        return lineDic
    }

    func updateUri(relativeUri: String, absoluteUri: String) {
        self.paramsString = self.paramsString.replacingOccurrences(of: relativeUri, with: absoluteUri)
        self.paramsObject.updateValue("\"\(absoluteUri)\"", forKey: PlaylistParser.HLSKeywords.uri.rawValue)
    }
    
    func joinLine() -> String {
        var joinedLine = self.tag + (self.paramsString.trimmingCharacters(in: .whitespacesAndNewlines) != String() ? ":" : "")
        if self.paramsObject.isEmpty {
            joinedLine += self.paramsString
        } else {
            self.paramsObject.forEach { key, value in
                joinedLine += "\(key)=\(value)"
                joinedLine += ","
            }
        }
        if let lastChar = joinedLine.last, lastChar == "," {
            joinedLine = String(joinedLine.dropLast())
        }
        return joinedLine
    }
}
