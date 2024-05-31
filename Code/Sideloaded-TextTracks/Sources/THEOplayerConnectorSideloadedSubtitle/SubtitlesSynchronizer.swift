//
//  SubtitlesSynchronizer.swift
//  SideloadedTextTracks
//
//  Created by Raffi on 30/04/2024.
//

import Foundation
import AVFoundation
import THEOplayerSDK

protocol SubtitlesSynchronizerDelegate: AnyObject {
    func didUpdateTimestamp(timestamp: SSTextTrackDescription.WebVttTimestamp)
}

class SubtitlesSynchronizer {
    private struct SyncTask {
        enum SyncTaskStatus {
            case idle
            case resolving
            case resolved
        }

        let webVtt: WebVTT
        var status: SyncTaskStatus = .idle
        var mode: THEOplayerSDK.TextTrackMode?
    }
    private typealias TrackID = String

    private weak var player: THEOplayerSDK.THEOplayer?
    private var trackSyncMap: [TrackID: SyncTask] = [:]
    weak var delegate: SubtitlesSynchronizerDelegate?

    init?(player: THEOplayerSDK.THEOplayer?) {
        guard let theoplayer: THEOplayerSDK.THEOplayer = player else {
            return
        }

        self.player = player

        _ = theoplayer.textTracks.addEventListener(type: THEOplayerSDK.TextTrackListEventTypes.ADD_TRACK, listener: { [weak self, weak theoplayer] event in
            guard let textTrack: THEOplayerSDK.TextTrack = event.track as? THEOplayerSDK.TextTrack,
                  let welf = self,
                  let textTrackDescriptions: [THEOplayerSDK.TextTrackDescription] = theoplayer?.source?.textTracks,
                  let textTrackDescription: SSTextTrackDescription = textTrackDescriptions.first(where: { $0.label == textTrack.label }) as? SSTextTrackDescription,
                  textTrackDescription.automaticTimestampSyncEnabled else {
                return
            }

            Self.getVttContent(urlString: textTrackDescription.src.absoluteString, completion: { content, error in
                let webVtt: WebVTT = .init(webVttContent: content)
                welf.trackSyncMap[textTrack.label] = SyncTask(webVtt: webVtt)
            })

            _ = textTrack.addEventListener(type: THEOplayerSDK.TextTrackEventTypes.EXIT_CUE, listener: { event in
                guard var textTrack: THEOplayerSDK.TextTrack = event.cue.track,
                      let task: SyncTask = welf.trackSyncMap[textTrack.label],
                      task.status == .idle else {
                    return
                }

                guard let cueContent: String = event.cue.contentString,
                      let webVttCue: WebVTT.WebVTTCue = task.webVtt.cues.first(where: { $0.text.contains(cueContent) }) else {
                    return
                }

                guard let currentTime: Double = theoplayer?.currentTime else {
                    return
                }

                let mode: THEOplayerSDK.TextTrackMode = textTrack.mode
                let scheduledEndTime: TimeInterval = webVttCue.endTime
                let delta: Double = scheduledEndTime - currentTime
                let threshold: Double = 0.1

                guard delta > threshold || delta < -threshold else {
                    return
                }

                let pts: String = .init(delta * 90000)
                let localTime: String = textTrackDescription.vttTimestamp.localTime ?? "00:00:00.000"
                self?.delegate?.didUpdateTimestamp(timestamp: .init(pts: pts, localTime: localTime))

                welf.trackSyncMap[textTrack.label]?.status = .resolving
                welf.trackSyncMap[textTrack.label]?.mode = mode
                textTrack.mode = .disabled
            })
        })

        _ = theoplayer.textTracks.addEventListener(type: THEOplayerSDK.TextTrackListEventTypes.CHANGE, listener: { [weak self] event in
            guard var textTrack: THEOplayerSDK.TextTrack = event.track as? THEOplayerSDK.TextTrack,
                  let welf = self,
                  let task: SyncTask = welf.trackSyncMap[textTrack.label],
                  task.status == .resolving else {
                return
            }

            welf.trackSyncMap[textTrack.label]?.status = .resolved
            if let mode: THEOplayerSDK.TextTrackMode = task.mode {
                textTrack.mode = mode
            }
        })
    }

    private static func getVttContent(urlString: String, completion: @escaping (_ content: String, _ error: Error?) -> Void) {
        guard let url: URL = .init(string: urlString) else {
            enum _Error: Error, CustomStringConvertible {
                case incorrectUrl
                public var description: String {
                    return "The URL provided is incorrect."
                }
            }
            completion(.init(), _Error.incorrectUrl)
            return
        }

        let request: URLRequest = .init(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, res, err in
            if let _data: Data = data,
               let contentString = String(data: _data, encoding: .utf8),
               err == nil {
                completion(contentString.withoutCarriageReturns, nil)
            } else {
                completion(.init(), err)
            }
        }
        task.resume()
    }
}
