//
//  THEOplayerEventsHandler.swift
//
//  Created by Raffi on 03/06/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

class THEOplayerEventsHandler {
    private let player: THEOplayerSDK.THEOplayer
    private let session: YOSession

    private var timeUpdateEventListener: THEOplayerSDK.EventListener?
    private var playingEventListener: THEOplayerSDK.EventListener?
    private var readyStateChangeEventListener: THEOplayerSDK.EventListener?
    private var pauseEventListener: THEOplayerSDK.EventListener?
    private var waitingEventListener: THEOplayerSDK.EventListener?
    private var endedEventListener: THEOplayerSDK.EventListener?
    private var sourceChangedEventListener: THEOplayerSDK.EventListener?

    private var didCallStart: Bool = false
    private var isWaiting: Bool = false

    init(player: THEOplayerSDK.THEOplayer, session: YOSession) {
        self.player = player
        self.session = session
        self.attachEventListeners()
    }

    private func attachEventListeners() {
        self.timeUpdateEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.TIME_UPDATE, listener: { [weak self] event in
            guard let welf: THEOplayerEventsHandler = self else { return }
            if welf.session.playbackMode != .YOLiveMode {
                welf.session.playheadDidChange(event.currentTime)
            }
        })

        self.playingEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener: { [weak self] event in
            guard let welf: THEOplayerEventsHandler = self else { return }
            if welf.didCallStart {
                if welf.isWaiting {
                    welf.session.playerEventDidOccur(.playbackContinueEvent, playhead: welf.player.currentTime)
                    welf.isWaiting = false
                } else {
                    welf.session.playerEventDidOccur(.playbackResumeEvent, playhead: welf.player.currentTime)
                }
            } else {
                welf.session.playerEventDidOccur(.playbackStartEvent, playhead: welf.player.currentTime)
                welf.didCallStart = true
            }
        })

        self.readyStateChangeEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.READY_STATE_CHANGE, listener: { [weak self] event in
            guard let welf: THEOplayerEventsHandler = self else { return }
            if event.readyState == .HAVE_FUTURE_DATA {
                welf.session.playerEventDidOccur(.playbackReadyEvent, playhead: welf.player.currentTime)
            }
        })

        self.pauseEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.PAUSE, listener: { [weak self] event in
            guard let welf: THEOplayerEventsHandler = self else { return }
            welf.session.playerEventDidOccur(.playbackPauseEvent, playhead: welf.player.currentTime)
        })

        self.waitingEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.WAITING, listener: { [weak self] event in
            guard let welf: THEOplayerEventsHandler = self else { return }
            welf.session.playerEventDidOccur(.playbackStallEvent, playhead: welf.player.currentTime)
            welf.isWaiting = true
        })

        self.endedEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.ENDED, listener: { [weak self] event in
            guard let welf: THEOplayerEventsHandler = self else { return }
            welf.session.playerEventDidOccur(.playbackStopEvent, playhead: welf.player.currentTime)
        })

        self.sourceChangedEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.SOURCE_CHANGE, listener: { [weak self] event in
            guard let welf: THEOplayerEventsHandler = self else { return }
            if event.source == nil {
                welf.session.playerEventDidOccur(.playbackStopEvent, playhead: welf.player.currentTime)
            }
        })
    }

    private func removeEventListeners() {
        if let timeUpdateEventListener: THEOplayerSDK.EventListener = self.timeUpdateEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.TIME_UPDATE, listener: timeUpdateEventListener)
        }

        if let playingEventListener: THEOplayerSDK.EventListener = self.playingEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener: playingEventListener)
        }

        if let readyStateChangeEventListener: THEOplayerSDK.EventListener = self.readyStateChangeEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.READY_STATE_CHANGE, listener: readyStateChangeEventListener)
        }

        if let pauseEventListener: THEOplayerSDK.EventListener = self.pauseEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.PAUSE, listener: pauseEventListener)
        }

        if let waitingEventListener: THEOplayerSDK.EventListener = self.waitingEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.WAITING, listener: waitingEventListener)
        }

        if let endedEventListener: THEOplayerSDK.EventListener = self.endedEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.ENDED, listener: endedEventListener)
        }

        if let sourceChangedEventListener: THEOplayerSDK.EventListener = self.sourceChangedEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.SOURCE_CHANGE, listener: sourceChangedEventListener)
        }
    }

    private func reset() {
        self.removeEventListeners()
        self.timeUpdateEventListener = nil
        self.playingEventListener = nil
        self.readyStateChangeEventListener = nil
        self.pauseEventListener = nil
        self.waitingEventListener = nil
        self.endedEventListener = nil
        self.sourceChangedEventListener = nil
        self.didCallStart = false
        self.isWaiting = false
    }

    deinit {
        self.reset()
    }
}
