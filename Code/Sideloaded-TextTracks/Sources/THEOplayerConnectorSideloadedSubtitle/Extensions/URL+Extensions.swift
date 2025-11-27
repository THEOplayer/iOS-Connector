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
            print("URL scheme is invalid or missing.")
            return false
        }

        guard let host = self.host,
              !host.isEmpty else {
            print("URL host is invalid or missing.")
            return false
        }

        let disallowedCharacterSet = CharacterSet.urlQueryAllowed.inverted
        guard self.absoluteString.rangeOfCharacter(from: disallowedCharacterSet) == nil else {
            print("URL contains invalid characters.")
            return false
        }

        return true
    }
}
