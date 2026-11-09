//
//  PlaylistParser.swift
//  THEOplayer_SDK
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation

class PlaylistParser {
    var manifestURL: URL
    var manifestData: Data?
    let request: URLRequest?
    
    init(url: URL, request: URLRequest?) {
        self.manifestURL = url
        self.manifestData = nil
        self.request = request
    }
    
    func loadManifest(_ headers: [String: String]? = nil) async -> Data? {
        var request = URLRequest(url: self.manifestURL)
        if let headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        if let (data, response) = try? await URLSession.shared.data(for: request) {
            // Update the manifestUrl to the url received in the response (to pickup possible url redirect)
            if let responseUrl = response.url {
                self.manifestURL = responseUrl
            }
            if self.isValidManifest(data: data) {
                self.manifestData = data
                return data
            } else {
                return nil
            }
        }
        return nil
    }
    
    func isValidManifest(data: Data) -> Bool {
        guard let manifestString = String(data: data, encoding: .utf8) else { return false }
        let allLines = manifestString.components(separatedBy: "\n")
        if allLines.count > 0 && allLines.first!.contains(ManifestTags.ExtM3U.rawValue) {
            return true
        }
        return false
    }
    
    func getFullURL(from path: String) -> URL? {
        let uri = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uri.isEmpty else { return nil }

        if let url = URL(string: uri, relativeTo: self.manifestURL) {
            return url.absoluteURL
        }

        // Before iOS 17, URL(string:) rejects invalid characters such as raw spaces.
        // Escape only those and keep existing %XX escapes and URL delimiters as written.
        var allowed = CharacterSet.urlQueryAllowed
        allowed.insert(charactersIn: "%#[]")
        guard let escaped = uri.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: escaped, relativeTo: self.manifestURL)?.absoluteURL
    }
    
    func updateRelativeUri(line: HLSLine) {
        if let uri = line.uriParameter,
           let fullURL = self.getFullURL(from: uri) {
            line.updateUri(relativeUri: uri, absoluteUri: fullURL.absoluteString)
        }
    }

    enum HLSKeywords: String {
        case uri = "URI"
        case type = "TYPE"
        case subtitles = "SUBTITLES"
        case groupId = "GROUP-ID"
    }
}
