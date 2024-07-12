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
    private var enterCueEventListener: THEOplayerSDK.EventListener?
    private var id3Track: THEOplayerSDK.TextTrack?
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
            self.id3Track = textTrack
            self.enterCueEventListener = textTrack.addEventListener(type: THEOplayerSDK.TextTrackEventTypes.ENTER_CUE) { [weak self] event in
                self?.enterCueEventHandler(event: event)
            }
        }
    }

    private func enterCueEventHandler(event: THEOplayerSDK.EnterCueEvent) {
        if let key: String = event.cue.contentDictionary?["id"],
           let value: String = event.cue.contentDictionary?["text"] {
            let _value: String = String(value[value.index(after: value.startIndex)..<value.endIndex])
            if key == "YMID" {
                self.metadata.ymid = _value
            } else if key == "YTYP" {
                self.metadata.ytyp = _value
            } else if key == "YSEQ" {
                self.metadata.yseq = _value
            } else if key == "YDUR" {
                self.metadata.ydur = _value
            }
        }

        if let metadata: YOTimedMetadata = YOTimedMetadata.create(withMediaId: self.metadata.ymid, sequence: self.metadata.yseq, type: self.metadata.ytyp, offset: self.metadata.ydur, playhead: event.cue.startTime ?? self.player.currentTime),
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

        if let id3Track: THEOplayerSDK.TextTrack = self.id3Track,
           let enterCueEventListener: THEOplayerSDK.EventListener = self.enterCueEventListener {
            id3Track.removeEventListener(type: THEOplayerSDK.TextTrackEventTypes.ENTER_CUE, listener: enterCueEventListener)
        }
    }

    private func reset() {
        self.removeEventListeners()
        self.addTrackEventListener = nil
        self.enterCueEventListener = nil
        self.id3Track = nil
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
