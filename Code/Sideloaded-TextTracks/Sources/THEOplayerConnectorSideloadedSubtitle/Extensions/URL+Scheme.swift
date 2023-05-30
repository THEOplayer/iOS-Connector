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
    
    func byConcatingScheme(scheme: URLScheme) -> URL? {
        let urlStr = self.absoluteString.byConcatingScheme(scheme: scheme)
        return URL(string: urlStr.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func byRemovingScheme(scheme: URLScheme) -> URL? {
        let urlStr = self.absoluteString.replaceFirst(of: scheme.urlScheme, with: String())
        return URL(string: urlStr.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
