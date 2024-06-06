//
//  YospaceID3MetadataHandler.swift
//
//  Created by Raffi on 30/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

class YospaceID3MetadataHandler {
    private let player: THEOplayerSDK.THEOplayer
    private let session: YOSession
    private var addTrackEventListener: THEOplayerSDK.EventListener?
    private var addCueEventListener: THEOplayerSDK.EventListener?
    private var metadata: YospaceTimedMetadata = .init()

    init(player: THEOplayerSDK.THEOplayer, session: YOSession) {
        self.player = player
        self.session = session
        self.addTrackEventListener = self.player.textTracks.addEventListener(type: THEOplayerSDK.TextTrackListEventTypes.ADD_TRACK) { [weak self] event in
            self?.addTrackEventHandler(event: event)
        }
    }

    private func addTrackEventHandler(event: THEOplayerSDK.AddTrackEvent) {
        if let textTrack: THEOplayerSDK.TextTrack = event.track as? THEOplayerSDK.TextTrack,
           textTrack.kind == THEOplayerSDK.TextTrackKind.metadata._rawValue,
           textTrack.type == "id3" {
            self.addCueEventListener = textTrack.addEventListener(type: THEOplayerSDK.TextTrackEventTypes.ADD_CUE) { [weak self] event in
                self?.addCueEventHandler(event: event)
            }
        }
    }

    private func addCueEventHandler(event: THEOplayerSDK.AddCueEvent) {
        if let key: String = event.cue.contentDictionary?["id"],
           let value: String = event.cue.contentDictionary?["text"] {
            let _value: String = String(value[value.index(after: value.startIndex)..<value.endIndex])
            if key == "YMID" {
                if !self.metadata.ymid.isEmpty {
                    self.metadata = YospaceTimedMetadata()
                }
                self.metadata.ymid = _value
            } else if key == "YTYP" {
                self.metadata.ytyp = _value
            } else if key == "YSEQ" {
                self.metadata.yseq = _value
            } else if key == "YDUR" {
                self.metadata.ydur = _value
            }
        }

        if let metadata: YOTimedMetadata = YOTimedMetadata.create(withMediaId: self.metadata.ymid, sequence: self.metadata.yseq, type: self.metadata.ytyp, offset: self.metadata.ydur, playhead: self.player.currentTime),
           self.metadata.isComplete {
            self.session.timedMetadataWasCollected(metadata)
            self.metadata = YospaceTimedMetadata()
        }
    }

    private func removeEventListeners() {
        guard let addTrackEventListener: THEOplayerSDK.EventListener = self.addTrackEventListener else {
            return
        }

        self.player.textTracks.removeEventListener(type: THEOplayerSDK.TextTrackListEventTypes.ADD_TRACK, listener: addTrackEventListener)

        if let addCueEventListener: THEOplayerSDK.EventListener = self.addCueEventListener,
           self.player.textTracks.count > 1 {
            self.player.textTracks[0].removeEventListener(type: THEOplayerSDK.TextTrackEventTypes.ADD_CUE, listener: addCueEventListener)
        }
    }

    private func reset() {
        self.removeEventListeners()
        self.addTrackEventListener = nil
        self.addCueEventListener = nil
        self.metadata = .init()
    }

    deinit {
        self.reset()
    }
}

fileprivate struct YospaceTimedMetadata {
    var ymid: String = .init()
    var ytyp: String = .init()
    var ydur: String = .init()
    var yseq: String = .init()

    var isComplete: Bool {
        return !self.ymid.isEmpty && !self.ytyp.isEmpty && !self.ydur.isEmpty && !self.yseq.isEmpty
    }
}