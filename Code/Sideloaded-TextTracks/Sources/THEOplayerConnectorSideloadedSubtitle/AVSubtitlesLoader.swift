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
    private let subtitles: [TextTrackDescription]
    private(set) var variantTotalDuration: Double = 0
    private let transformer = SubtitlesTransformer()
    
    init(subtitles: [TextTrackDescription]) {
        self.subtitles = subtitles
    }
    
    func handleMasterManifestRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let originalURL = request.request.url?.withScheme(newScheme: URLScheme.https) else {
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
        guard let customSchemeURL = request.request.url,
              let originalURLString = customSchemeURL.absoluteString.byRemovingScheme(scheme: URLScheme.variantm3u8),
              let originalURL = URL(string:originalURLString) else {
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
        
        guard let originalURLString = customSchemeURL.absoluteString.byRemovingScheme(scheme: URLScheme.subtitlesm3u8),
              let originalURL = URL(string: originalURLString) else {
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

    func handleSubtitleContent(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let customSchemeURL = request.request.url else {
            return false
        }

        guard let originalURLString = customSchemeURL.absoluteString.byRemovingScheme(scheme: URLScheme.subtitle),
              let originalURL = URL(string: originalURLString) else {
            print("[AVSubtitlesLoader] ERROR: Failed to revert subtitle URL!")
            return false
        }

        let trackDescription: THEOplayerSDK.TextTrackDescription? = self.findTrackDescription(by: originalURL)
        let format: THEOplayerSDK.TextTrackFormat = trackDescription?.format ?? .WebVTT
        let timestamp: SSTextTrackDescription.WebVttTimestamp? = (trackDescription as? SSTextTrackDescription)?.vttTimestamp
        let req: URLRequest? = self.transformer.composeTransformationRequest(with: originalURL.absoluteString, format: format, timestamp: timestamp)
        let response = HTTPURLResponse(url: originalURL, statusCode: 301, httpVersion: nil, headerFields: nil)
        request.response = response
        request.redirect = req
        request.finishLoading()

        return true
    }
    
    fileprivate func getSubtitleManifest(for originalURL: URL) -> String {
        let subtitlesURL: String = originalURL.absoluteString.byConcatenatingScheme(scheme: URLScheme.subtitle)
        // if the variantTotalDuration is equal to zero then we can use a higher number as AVPlayer is not expecting the EXACT duration but the MAXIMUM duration that the stream can reach
        return """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-MEDIA-SEQUENCE:0
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXT-X-TARGETDURATION:\(self.variantTotalDuration == 0 ? Int.max : Int(self.variantTotalDuration))
        #EXTINF:\(self.variantTotalDuration == 0 ? String(Int.max) : String(format: "%.3f", self.variantTotalDuration))
        \(subtitlesURL)
        #EXT-X-ENDLIST
        """
    }

    private func findTrackDescription(by subtitleURL: URL) -> THEOplayerSDK.TextTrackDescription? {
        // find the track definition
        guard let track: THEOplayerSDK.TextTrackDescription = self.subtitles.first(where: { subtitle in
            return subtitle.src.absoluteString == subtitleURL.absoluteString
        }) else {
            return nil
        }
        return track
    }
}

enum URLScheme: String {
    case skd = "skd"
    case https = "https"
    case masterm3u8 = "interceptedm3u8" // master manifest
    case subtitlesm3u8 = "subtitlesm3u8" // subtitle manifest
    case subtitle = "subtitle" // subtitle data
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
            print("[AVSubtitlesLoader] loadingRequest", loadingRequest.request.url?.absoluteString ?? "")
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
        case URLScheme.subtitle.name:
            // intercept subtitle content to modify (ie. SRT -> VTT, add time offset, etc.)
            return self.handleSubtitleContent(loadingRequest)
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
            if let sideLoadedTextTracks = SourceValidator.getValidTextTracks(source) {
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

#if os(iOS)
extension Cache {
    /**
    Creates a CachingTask and activates the side-loaded subtitle helper logic

     - Remark:
        - Once used this method, always use it to cache a source (even if there are no sideloaded subtitles in it), otherwise the subtitle helper logic can break the caching behavior
     */
    public func createTaskWithSubtitles(source: SourceDescription, parameters: CachingParameters?) -> CachingTask? {
        if let sideLoadedTextTracks = SourceValidator.getValidTextTracks(source) {
            let subtitleLoader = AVSubtitlesLoader(subtitles: sideLoadedTextTracks)
            self.developerSettings?.manifestInterceptor = subtitleLoader
        } else {
            self.developerSettings?.manifestInterceptor = nil
        }

        return createTask(source: source, parameters: parameters)
    }
}
#endif

/// A subclass of `TextTrackDescription` which extends and adds additional functionality.
public class SSTextTrackDescription: TextTrackDescription {
    /// A structure that represents the X-TIMESTAMP-MAP tag for WebVTT subtitles in the HLS spec.
    public struct WebVttTimestamp {
        /// The timestamp that represents the MPEGTS property of the X-TIMESTAMP-MAP tag.
        public var pts: String?
        /// The local time that represents the LOCAL property of the X-TIMESTAMP-MAP tag.
        public var localTime: String?

        /// :nodoc:
        public init(pts: String? = nil, localTime: String? = nil) {
            self.pts = pts
            self.localTime = localTime
        }
    }

    /**
     Property that stores the value of the X-TIMESTAMP-MAP tag.

     - Remark:
        - Setting this property will add/replace the X-TIMESTAMP-MAP specified in the WebVTT source. Both `pts` and `localTime` properties should be different than nil.
        - If the source already contains a X-TIMESTAMP-MAP tag, the values will not be automatically set. To get the values, use the `extractSourceTimestamp` method.
     */
    public var vttTimestamp: WebVttTimestamp = .init()

    /**
     Method that returns a closure that provides the values of the X-TIMESTAMP-MAP tag specified in the WebVTT source, represented using the `WebVttTimestamp` structure.

     - Remark:
        - Always returns a timestamp, but if the source does not specify the X-TIMESTAMP-MAP tag then the properties of the timestamp will be nil.
     */
    public func extractSourceTimestamp(completion: @escaping (_ timestamp: WebVttTimestamp, _ error: Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: URLRequest(url: self.src)) { data, res, err in
            if let _data: Data = data,
               let contentString = String(data: _data, encoding: .utf8),
               err == nil {
                if let values: (String, String) = TimestampStringUtils.getTimestampValues(from: contentString) {
                    completion(.init(pts: values.0, localTime: values.1), nil)
                } else {
                    enum _Error: Error, CustomStringConvertible {
                        case timestampNotFound
                        public var description: String {
                            return "Could not find a timestamp in the WebVTT file."
                        }
                    }
                    completion(.init(), _Error.timestampNotFound)
                }
            } else {
                completion(.init(), err)
            }
        }
        task.resume()
    }
}
