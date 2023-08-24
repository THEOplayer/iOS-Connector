//
//  TimestampStringUtils.swift
//  
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation

class TimestampStringUtils {
    private static let timestampTag: String = "X-TIMESTAMP-MAP"
    private static let ptsKey: String = "MPEGTS"
    private static let localKey: String = "LOCAL"

    enum TimestampOrigin {
        case SubtitleManifest
        case QualityManifest
    }

    private static func getTimestampValueIndexes(from string: String, origin: TimestampOrigin) -> (String.Index, String.Index)? {
        let _operator = origin == .SubtitleManifest ? "=" : ":"
        guard let startIndex: String.Index = string.range(of: "\(Self.timestampTag)\(_operator)")?.upperBound,
              let endIndex: String.Index = string.suffix(from: startIndex).range(of: "\n")?.lowerBound else {
            return nil
        }
        return (startIndex, endIndex)
    }

    private static func getTimestampValue(from string: String, origin: TimestampOrigin) -> String? {
        guard let indexes: (String.Index, String.Index) = Self.getTimestampValueIndexes(from: string, origin: origin) else {
            return nil
        }
        return String(string[indexes.0...string.index(before: indexes.1)])
    }

    static func getTimestampValues(from string: String, origin: TimestampOrigin = .SubtitleManifest) -> (String, String)? {
        guard let timestampValue: String = Self.getTimestampValue(from: string, origin: origin) else {
            return nil
        }

        let parameters: [String] = timestampValue.components(separatedBy: ",")
        var pts: String?
        var local: String?
        for parameter in parameters {
            let _operator = origin == .SubtitleManifest ? ":" : "="
            let keyValue: [String] = parameter.components(separatedBy: _operator)
            if let key: String = keyValue.first {
                if key == Self.ptsKey,
                    let value: String = keyValue.last {
                    pts = value
                } else if key == Self.localKey {
                    local = keyValue.dropFirst().joined(separator: ":")
                }
            }
        }

        if let _local: String = local,
           let _pts: String = pts {
            return (_pts, _local)
        }
        return nil
    }

    static func overrideTimestamp(in string: String, with values: (String, String)) -> String? {
        guard let indexes: (String.Index, String.Index) = Self.getTimestampValueIndexes(from: string, origin: .SubtitleManifest) else {
            print("[AVSubtitlesLoader] ERROR: Failed to override timestamp.")
            return nil
        }

        var _string: String = string
        _string.replaceSubrange(indexes.0...indexes.1, with: "\(Self.ptsKey):\(values.0),\(Self.localKey):\(values.1)\n")
        return _string
    }

    static func insertTimestamp(in string: String, with values: (String, String)) -> String? {
        guard let newlineIndex: String.Index = string.range(of: "\n")?.upperBound else {
            print("[AVSubtitlesLoader] ERROR: Failed to add timestamp.")
            return nil
        }

        var _string: String = string
        _string.insert(contentsOf: "\(Self.timestampTag)=\(Self.ptsKey):\(values.0),\(Self.localKey):\(values.1)\n", at: newlineIndex)
        return _string
    }
}
