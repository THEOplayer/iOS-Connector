//
//  AVURLAssetExtensions.swift
//  THEOplayer_SDK
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation
import AVFoundation

extension URL {
    func withScheme(newScheme: URLScheme) -> URL? {
        guard let oldScheme = self.scheme else {
            return nil
        }
        guard let range = self.absoluteString.range(of: oldScheme + "://") else {
            return nil
        }
        return URL(string: self.absoluteString.replacingCharacters(in: range, with: newScheme.urlScheme))
    }
    
    func withScheme(newScheme: String) -> URL? {
        guard let oldScheme = self.scheme else {
            return nil
        }
        guard let range = self.absoluteString.range(of: oldScheme + "://") else {
            return nil
        }
        return URL(string: self.absoluteString.replacingCharacters(in: range, with: newScheme + "://"))
    }

    var isValid: Bool {
        guard self.scheme != nil else {
            print("[AVSubtitlesLoader] URL scheme is invalid or missing.")
            return false
        }

        guard let host = self.host,
              !host.isEmpty else {
            print("[AVSubtitlesLoader] URL host is invalid or missing.")
            return false
        }

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.insert("%")
        guard self.absoluteString.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil else {
            print("[AVSubtitlesLoader] URL contains invalid characters.")
            return false
        }

        return true
    }
}
