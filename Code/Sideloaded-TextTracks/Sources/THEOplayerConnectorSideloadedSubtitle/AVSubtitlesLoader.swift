//
//  AVSubtitlesLoader.swift
//  THEOplayer_SDK
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation
import AVFoundation
import THEOplayerSDK

class AVSubtitlesLoader: NSObject {
    private let subtitles: [TextTrackDescription]?
    private(set) var variantTotalDuration: Double = 0
    
    init(subtitles: [TextTrackDescription]) {
        self.subtitles = subtitles
    }
    
    func handleMasterManifestRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let originalURL = request.request.url?.withScheme(newScheme: URLScheme.https),
                let subtitles = self.subtitles else {
            return false
        }
        
        MasterPlaylistParser(url: originalURL).sideLoadSubtitles(subtitles: subtitles) { data in
            guard let masterManifestData = data else {
                print("[AVSubtitlesLoader] ERROR: Couldn't find manifest data")
                request.finishLoading(with: URLError(URLError.cannotParseResponse))
                return
            }
            let response = HTTPURLResponse(url: originalURL, statusCode: 200, httpVersion: nil, headerFields: nil)
            request.response = response
            request.dataRequest?.respond(with: masterManifestData)
            request.finishLoading()
        }
        return true
    }
    
    func handleVariantManifest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let customSchemeURL = request.request.url, let originalURL = customSchemeURL.byRemovingScheme(scheme: URLScheme.variantm3u8) else {
            print("[AVSubtitlesLoader] ERROR: Variant manifest is invalid")
            request.finishLoading(with: URLError(URLError.unsupportedURL))
            return false
        }
        VariantPlaylistParser(url: originalURL).parse { playlist in
            guard let playlist = playlist, let responseData = playlist.manifestData else {
                print("[AVSubtitlesLoader] ERROR: Couldn't find variant data")
                request.finishLoading(with: URLError(URLError.cannotParseResponse))
                return
            }
            self.variantTotalDuration = playlist.totalPlayListDuration
            let response = HTTPURLResponse(url: originalURL, statusCode: 200, httpVersion: nil, headerFields: nil)
            request.response = response
            request.dataRequest?.respond(with: responseData)
            request.finishLoading()
        }
        return true
    }
    
    func handleSubtitles(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let customSchemeURL = request.request.url else {
            return false
        }
        
        guard let originalURL = customSchemeURL.byRemovingScheme(scheme: URLScheme.subtitlesm3u8) else {
            print("[AVSubtitlesLoader] ERROR: Failed to revert subtitle URL!")
            return false
        }
        
        let subtitlem3u8 = self.getSubtitleManifest(for: originalURL)
        
        if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
            print("[AVSubtitlesLoader] SUBTITLE: +++++++")
            print(subtitlem3u8)
            print("[AVSubtitlesLoader] SUBTITLE: ------")
        }
        
        guard let data = subtitlem3u8.data(using: .utf8) else {
            return false
        }
        
        let response = HTTPURLResponse(url: originalURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        request.response = response
        request.dataRequest?.respond(with: data)
        request.finishLoading()
        
        return true
    }
    
    fileprivate func getSubtitleManifest(for originalURL: URL) -> String {
        // if the variantTotalDuration is equal to zero then we can use a higher number as AVPlayer is not expecting the EXACT duration but the MAXIMUM duration that the stream can reach
        return """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-MEDIA-SEQUENCE:0
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXT-X-TARGETDURATION:\(self.variantTotalDuration == 0 ? Int.max : Int(self.variantTotalDuration))
        #EXTINF:\(self.variantTotalDuration == 0 ? String(Int.max) : String(format: "%.3f", self.variantTotalDuration))
        \(originalURL.absoluteString)
        #EXT-X-ENDLIST
        """
    }
}

enum URLScheme: String {
    case skd = "skd"
    case https = "https"
    case masterm3u8 = "interceptedm3u8" // master manifest
    case subtitlesm3u8 = "subtitlesm3u8" // subtitle manifest
    case variantm3u8 = "variantm3u8" // variant manifest
    
    var name: String {
        return self.rawValue
    }
    
    var urlScheme: String {
        return self.rawValue + "://"
    }
}

extension AVSubtitlesLoader: ManifestInterceptor {
    var customScheme: String {
        //the initial interception scheme
        URLScheme.masterm3u8.urlScheme
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
            print("[AVSubtitlesLoader] renewalRequest", loadingRequest.request.url?.absoluteString ?? "")
        }
        return intercept(loadingRequest: loadingRequest)

    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
            print("[AVSubtitlesLoader] renewalRequest", renewalRequest.request.url?.absoluteString ?? "")
        }
        return intercept(loadingRequest: renewalRequest)
    }
    
    private func intercept(loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let scheme = loadingRequest.request.url?.scheme else {
            return false
        }
        switch scheme {
        case URLScheme.masterm3u8.name:
            // intercept the master manifest to append the subtitles
            return self.handleMasterManifestRequest(loadingRequest)
        case URLScheme.variantm3u8.name:
            // intercept the variant manifest to get the duration
            return self.handleVariantManifest(loadingRequest)
        case URLScheme.subtitlesm3u8.name:
            // intercept the subtitle request to respond with the HLS subtitle
            return self.handleSubtitles(loadingRequest)
        default:
            break
        }
        
        return false
    }
    
}

extension THEOplayer {
    /**
    Sets a source on THEOplayer and activates the side-loaded subtitle helper logic
     
     - Remark:
        - Once used this method, always use it to set a source (even if there are no sideloaded subtitles in it), otherwise the subtitle helper logic can break the playback behavior
     */
    public func setSourceWithSubtitles(source: SourceDescription?){
        
        if let source = source {
            if let sideLoadedTextTracks = source.textTracks, !sideLoadedTextTracks.isEmpty {
                let subtitleLoader = AVSubtitlesLoader(subtitles: sideLoadedTextTracks)
                self.developerSettings?.manifestInterceptor = subtitleLoader
            } else {
                self.developerSettings?.manifestInterceptor = nil
            }
        } else {
            self.developerSettings?.manifestInterceptor = nil
        }
        
        self.source = source
    }
}
