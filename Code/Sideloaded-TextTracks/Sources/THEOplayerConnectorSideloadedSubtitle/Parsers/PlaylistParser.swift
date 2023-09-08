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
    
    init(url: URL) {
        self.manifestURL = url
        self.manifestData = nil
    }
    
    func loadManifest(completion: @escaping (_ success: Bool) -> ()) {
        URLSession.shared.dataTask(with: self.manifestURL) { [weak self] data, response, error in
            guard let responseData = data, let self = self else {
                completion(false)
                return
            }
			// Update the manifestUrl to the url received in the response (to pickup possible url redirect)
			if let responseUrl = response?.url {
			    self.manifestURL = responseUrl
			}
            if self.isValidManifest(data: responseData) {
                self.manifestData = responseData
                completion(true)
            } else {
                completion(false)
            }
        }
        .resume()
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
        guard var url = URL(string: path.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        if url.scheme == nil {
            url = self.manifestURL.deletingLastPathComponent().appendingPathComponent(path)
        }
        return url
    }
    
    enum HLSKeywords: String {
        case uri = "URI"
        case type = "TYPE"
        case subtitles = "SUBTITLES"
        case groupId = "GROUP-ID"
    }
}
