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
    private static var instances: [AVSubtitlesLoader] = []
    static func addInstance(_ loader: AVSubtitlesLoader) { Self.instances.append(loader) }
    static func removeInstance(by id: String) {
        Self.instances.removeAll { $0._id == id }
    }

    private let subtitles: [TextTrackDescription]
    private let transformer = SubtitlesTransformer()
    private let synchronizer: SubtitlesSynchronizer?
    private let _id: String
    private var variantTotalDuration: Double = 0
    
    init(subtitles: [TextTrackDescription], id: String, player: THEOplayer? = nil, cachingTask: CachingTask? = nil) {
        self.subtitles = subtitles
        self._id = id
        self.synchronizer = SubtitlesSynchronizer(player: player)
        self.synchronizer?.delegate = self.transformer

        super.init()

        _ = player?.addEventListener(type: PlayerEventTypes.DESTROY, listener: { [weak self] destroyEvent in self?.handleDestroyEvent() })
        _ = cachingTask?.addEventListener(type: CachingTaskEventTypes.STATE_CHANGE, listener: { [weak self] cachingTaskStateChangeEvent in self?.handleCachingTaskStateChangeEvent(task: cachingTask) })
    }

    func handleMasterManifestRequest(_ url: URL) async -> Data? {
        let parser = MasterPlaylistParser(url: url)

        guard let responseData = await parser.sideLoadSubtitles(subtitles: subtitles) else {
            print("[AVSubtitlesLoader] ERROR: Couldn't find manifest data")
            return nil
        }

        return responseData
    }
    
    func handleVariantManifest(_ url: URL) async -> Data? {
        let parser = VariantPlaylistParser(url: url)

        guard let playlist = await parser.parse(),
           let responseData = playlist.manifestData else {
            print("[AVSubtitlesLoader] ERROR: Couldn't find variant data")
            return nil
        }

        self.variantTotalDuration = playlist.totalPlayListDuration
        return responseData
    }

    func handleSubtitles(_ url: URL) -> Data? {
        let subtitlem3u8 = self.getSubtitleManifest(for: url)
        
        if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
            print("[AVSubtitlesLoader] SUBTITLE: +++++++")
            print(subtitlem3u8)
            print("[AVSubtitlesLoader] SUBTITLE: ------")
        }

        return subtitlem3u8.data(using: .utf8)
    }
    
    fileprivate func getSubtitleManifest(for originalURL: URL) -> String {
        let trackDescription: THEOplayerSDK.TextTrackDescription? = self.findTrackDescription(by: originalURL)
        let format: THEOplayerSDK.TextTrackFormat = trackDescription?.format ?? .WebVTT
        let timestamp: SSTextTrackDescription.WebVttTimestamp? = (trackDescription as? SSTextTrackDescription)?.vttTimestamp
        let autosync: Bool? = (trackDescription as? SSTextTrackDescription)?.automaticTimestampSyncEnabled
        let subtitlesMediaURL: String
        if (timestamp?.localTime == nil && timestamp?.pts == nil && format == .WebVTT && autosync == nil) {
            subtitlesMediaURL = originalURL.absoluteString
        } else {
            subtitlesMediaURL = self.transformer.composeTranformationUrl(with: originalURL.absoluteString, format: format, timestamp: timestamp)
        }
        
        // if the variantTotalDuration is equal to zero then we can use a higher number as AVPlayer is not expecting the EXACT duration but the MAXIMUM duration that the stream can reach
        let DEFAULT_DURATION = 604800 // Corresponds to a week in seconds, as AVPplayer didn't handle Int.max as a default value well.
        let subtitleSegmentDuration = self.variantTotalDuration == 0 ? DEFAULT_DURATION : Int(self.variantTotalDuration)
        
        return """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-MEDIA-SEQUENCE:0
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXT-X-TARGETDURATION:\(Int(subtitleSegmentDuration))
        #EXTINF:\(String(format: "%.3f", Double(subtitleSegmentDuration)))
        \(subtitlesMediaURL)
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

    private func handleDestroyEvent() {
        Self.removeInstance(by: _id)
    }

    private func handleCachingTaskStateChangeEvent(task: CachingTask?) {
        guard let task,
              task.status == .evicted else { return }
        Self.removeInstance(by: task.id)
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

extension AVSubtitlesLoader: MediaPlaylistInterceptor {
    func shouldInterceptPlaylistRequest(type: HlsPlaylistType) -> Bool { false }
    func didInterceptPlaylistRequest(type: HlsPlaylistType, request: URLRequest) async throws -> URLRequest { request }

    func failedToPerformURLRequest(request: URLRequest, response: URLResponse) {
        if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
            print("[AVSubtitlesLoader] failedToPerformURLRequest", request.url?.absoluteString ?? "")
        }
    }

    func shouldInterceptPlaylistResponse(type: HlsPlaylistType) -> Bool { true }
    func didInterceptPlaylistResponse(type: HlsPlaylistType, url: URL, response: URLResponse, data: Data) async throws -> Data {
        if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
            print("[AVSubtitlesLoader] intercept url", url.absoluteString, self)
        }
        return await interceptResponse(type: type, url: url, data: data)
    }

    private func interceptResponse(type: HlsPlaylistType, url: URL, data: Data) async -> Data {
        switch type {
        case .master :
            // intercept the master manifest to append the subtitles
            return await self.handleMasterManifestRequest(url) ?? data
        case .video:
            // intercept the variant manifest to get the duration
            return await self.handleVariantManifest(url) ?? data
        case .subtitles:
            // intercept the subtitle request to respond with the HLS subtitle
            return self.handleSubtitles(url) ?? data
        default:
            break
        }
        return data
    }
}

extension THEOplayer {
    /**
    Sets a source on THEOplayer and activates the side-loaded subtitle helper logic
     
     - Remark:
        - Once used this method, always use it to set a source (even if there are no sideloaded subtitles in it), otherwise the subtitle helper logic can break the playback behavior
     */
    public func setSourceWithSubtitles(source: SourceDescription?) {
        if let source = source,
           let sideLoadedTextTracks = SourceValidator.getValidTextTracks(source) {
                let loader = AVSubtitlesLoader(
                    subtitles: sideLoadedTextTracks,
                    id: String(self.uid),
                    player: self
                )
                AVSubtitlesLoader.addInstance(loader)
                self.network.addMediaPlaylistInterceptor(loader)
        } else {
            AVSubtitlesLoader.removeInstance(by: String(self.uid))
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
        guard let cachingTask = createTask(source: source, parameters: parameters) else { return nil }
        if let sideLoadedTextTracks = SourceValidator.getValidTextTracks(source) {
            let loader = AVSubtitlesLoader(
                subtitles: sideLoadedTextTracks,
                id: cachingTask.id,
                cachingTask: cachingTask
            )
            AVSubtitlesLoader.addInstance(loader)
            cachingTask.network.addMediaPlaylistInterceptor(loader)
        }

        return cachingTask
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
     When enabled, the player will attempt to synchronize the text track cues with the current playback time by overwriting the presentation timestamp mapping. Defaults to `false`.

     - Remark:
        - Enabling this might cause a brief flash to the first displayed cue. This can occur when a cue is present while the syncing takes effect.
     */
    public var automaticTimestampSyncEnabled: Bool = false

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
