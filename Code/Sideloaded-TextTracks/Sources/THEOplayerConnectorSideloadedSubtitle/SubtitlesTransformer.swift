//
//  SubtitlesTransformer.swift
//
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation
import AVFoundation
import Swifter
import SwiftSubtitles
import THEOplayerSDK

class SubtitlesTransformer {
    private let server = HttpServer()
    private static let TRANSFORM_ROUTE: String = "transformSubtitle"
    private static let PORT_RANGE: Range<in_port_t> = 8000..<49151
    private var retryAttemptsLeft: Int = 9
    private var port: in_port_t

    init() {
        self.port = .random(in: Self.PORT_RANGE)
        self.setupServerRoutes()
        self.startServer()
    }

    enum Parameters: String {
        case contentUrl
        case format
        case timestampPts
        case timestampLocaltime

        func getValue(from tupleArray: [(String, String)]) -> String? {
            return tupleArray.first(where: { $0.0 == self.rawValue })?.1
        }
    }

    // If AirPlay is connected, then use the IP address of the cast device, else use localhost since it's on the same device.
    // Dynamically loads again when switching back and forth between casting/playing locally.
    var host: String {
        let defaultHost = "localhost"
        return AVAudioSession.sharedInstance().isConnectedToAirplayDevice() ? (DeviceUtil.DEVICE_IP ?? defaultHost) : defaultHost
    }

    func composeTranformationUrl(with subtitlesURL: String, format: THEOplayerSDK.TextTrackFormat, timestamp: SSTextTrackDescription.WebVttTimestamp?) -> String {
        var urlComps = URLComponents(string: "http://\(self.host):\(self.port)/\(SubtitlesTransformer.TRANSFORM_ROUTE)")!
        urlComps.queryItems = [URLQueryItem(name: Parameters.contentUrl.rawValue, value: subtitlesURL)]
        urlComps.queryItems!.append(URLQueryItem(name: Parameters.format.rawValue, value: format._rawValue))

        if let pts: String = timestamp?.pts,
           let localTime: String = timestamp?.localTime {
            urlComps.queryItems!.append(URLQueryItem(name: Parameters.timestampPts.rawValue, value: pts))
            urlComps.queryItems!.append(URLQueryItem(name: Parameters.timestampLocaltime.rawValue, value: localTime))
        }
        
        return urlComps.url?.absoluteString ?? subtitlesURL
    }

    private func setupServerRoutes() {
        let handler: (HttpRequest) -> HttpResponse = { req in
            // Always return with HttpResponse.ok to fail gracefully. Otherwise player will stall.
            guard let contentURLString: String = Parameters.contentUrl.getValue(from: req.queryParams),
                  let decodedContentUrlString: String = contentURLString.removingPercentEncoding,
                  let contentUrl: URL = URL(string: decodedContentUrlString) else {
                let errorMessage: String = "Missing subtitle content URL."
                print("[AVSubtitlesLoader] ERROR: \(errorMessage)")
                return HttpResponse.ok(.text(errorMessage))
            }

            let (data, err) = URLSession.shared.synchronousDataTask(urlrequest: URLRequest(url: contentUrl))
            if let error: Error = err {
                let errorMessage: String = "Missing subtitle content. Reason: \(error.localizedDescription)"
                print("[AVSubtitlesLoader] ERROR: \(errorMessage)")
                return HttpResponse.ok(.text(errorMessage))
            }
            guard let contentData: Data = data,
                  let _contentString: String = String(data: contentData, encoding: .utf8)?.removingPercentEncoding ?? String(data: contentData, encoding: .utf8) else {
                let errorMessage: String = "Missing subtitle content. Reason: Failed to encode content string."
                print("[AVSubtitlesLoader] ERROR: \(errorMessage)")
                return HttpResponse.ok(.text(errorMessage))
            }
            var contentString: String = _contentString.replacingOccurrences(of: "\r\n", with: "\n")

            // SRT to VTT
            if Parameters.format.getValue(from: req.queryParams) == THEOplayerSDK.TextTrackFormat.SRT._rawValue {
                do {
                    let subtitles: Subtitles = try Subtitles.Coder.SRT().decode(contentString)
                    contentString = try Subtitles.Coder.VTT().encode(subtitles: subtitles)
                } catch let err {
                    print("[AVSubtitlesLoader] ERROR: Converting SRT to VTT", err.localizedDescription)
                    return HttpResponse.ok(.text(err.localizedDescription))
                }
            }

            // Add/replace VTT timestamp
            if let timestampPts: String = Parameters.timestampPts.getValue(from: req.queryParams),
               let timestampLocalTime: String = Parameters.timestampLocaltime.getValue(from: req.queryParams) {
                // if timestamp exists replace it, else add
                if let modifiedString: String = TimestampStringUtils.overrideTimestamp(in: contentString, with: (timestampPts, timestampLocalTime)) {
                    contentString = modifiedString
                } else if let modifiedString: String = TimestampStringUtils.insertTimestamp(in: contentString, with: (timestampPts, timestampLocalTime)) {
                    contentString = modifiedString
                }
            }

            if THEOplayerConnectorSideloadedSubtitle.SHOW_DEBUG_LOGS {
                print("[AVSubtitlesLoader] Transformed subtitle", contentString)
            }
            return HttpResponse.ok(.text(contentString))
        }
        self.server["/\(Self.TRANSFORM_ROUTE)"] = handler
    }

    private func startServer() {
        do {
            try self.server.start(self.port)
        } catch SocketError.bindFailed(let message) where message == "Address already in use" {
            print("[AVSubtitlesLoader] ERROR starting local server:", message)

            guard self.retryAttemptsLeft > 0 else {
                return
            }

            self.retryAttemptsLeft -= 1
            self.port = .random(in: Self.PORT_RANGE)
            self.startServer()
        } catch let err {
            print("[AVSubtitlesLoader] ERROR starting local server:", err)
        }
    }

    deinit {
        self.server.stop()
    }
}
