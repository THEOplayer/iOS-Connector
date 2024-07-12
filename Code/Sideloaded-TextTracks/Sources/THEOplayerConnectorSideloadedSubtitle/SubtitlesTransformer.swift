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
    private var parameters: Parameters?

    init() {
        self.port = .random(in: Self.PORT_RANGE)
        self.setupServerRoutes()
        self.startServer()
    }

    private struct Parameters {
        let contentUrl: String
        let format: THEOplayerSDK.TextTrackFormat
        var timestamp: SSTextTrackDescription.WebVttTimestamp?
    }

    // If AirPlay is connected, then use the IP address of the cast device, else use localhost since it's on the same device.
    // Dynamically loads again when switching back and forth between casting/playing locally.
    var host: String {
        let defaultHost = "localhost"
        return AVAudioSession.sharedInstance().isConnectedToAirplayDevice() ? (DeviceUtil.DEVICE_IP ?? defaultHost) : defaultHost
    }

    func composeTranformationUrl(with subtitlesURL: String, format: THEOplayerSDK.TextTrackFormat, timestamp: SSTextTrackDescription.WebVttTimestamp?) -> String {
        self.parameters = Parameters(contentUrl: subtitlesURL, format: format, timestamp: timestamp)
        let urlComps = URLComponents(string: "http://\(self.host):\(self.port)/\(SubtitlesTransformer.TRANSFORM_ROUTE)")!
        return urlComps.url?.absoluteString ?? subtitlesURL
    }

    private func setupServerRoutes() {
        let handler: (HttpRequest) -> HttpResponse = { req in
            // Always return with HttpResponse.ok to fail gracefully. Otherwise player will stall.
            guard let contentURLString: String = self.parameters?.contentUrl,
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
            if self.parameters?.format == THEOplayerSDK.TextTrackFormat.SRT {
                do {
                    let subtitles: Subtitles = try Subtitles.Coder.SRT().decode(contentString)
                    contentString = try Subtitles.Coder.VTT().encode(subtitles: subtitles)
                } catch let err {
                    print("[AVSubtitlesLoader] ERROR: Converting SRT to VTT", err.localizedDescription)
                    return HttpResponse.ok(.text(err.localizedDescription))
                }
            }

            // Add/replace VTT timestamp
            if let timestampPts: String = self.parameters?.timestamp?.pts,
               let timestampLocalTime: String = self.parameters?.timestamp?.localTime {
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

    private func reset() {
        self.parameters = nil
    }

    deinit {
        self.reset()
        self.server.stop()
    }
}

extension SubtitlesTransformer: SubtitlesSynchronizerDelegate {
    func didUpdateTimestamp(timestamp: SSTextTrackDescription.WebVttTimestamp) {
        self.parameters?.timestamp = timestamp
    }
}
