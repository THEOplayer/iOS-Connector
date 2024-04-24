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
        // Remove any existing percentencoding and add 1 pass of percentEncoding to make sure correct URL can be build up on all iOS version
        guard let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines).removingPercentEncoding?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        var url: URL? = nil
        if #available(iOS 17.0, *) {
            url = URL(string: trimmedPath, encodingInvalidCharacters: false) // don't allow an extra percentEncoding pass.
        } else {
            url = URL(string: trimmedPath)
        }
        if let createdUrl = url,
           createdUrl.scheme == nil,
           let decodedPath = trimmedPath.removingPercentEncoding { // drop the percentEncoding as this will be reapplied by appendingPathComponent
            return self.manifestURL.deletingLastPathComponent().appendingPathComponent(decodedPath)
        }
        
        return url
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
