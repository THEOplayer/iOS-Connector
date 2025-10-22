//
//  BasicEventForwarder.swift
//  

import THEOplayerSDK
import THEOplayerConnectorUtilities
import AVFoundation

/// A handle that registers basic playback listeners on a theoplayer and removes them on deinit
class PlayerEventForwarder {
    private let playerObserver: DispatchObserver
    private let networkObserver: DispatchObserver
    
    init(player: THEOplayer, handler: PlayerHandler) {
        self.playerObserver = .init(
            dispatcher: player,
            eventListeners: Self.forwardEvents(from: player, to: handler)
        )
        self.networkObserver = .init(
            dispatcher: player.network,
            eventListeners: [
                player.network.addRemovableEventListener(
                    type: NetworkEventTypes.ERROR,
                    listener: handler.networkError
                )
            ]
        )
    }
    
    static func forwardEvents(from player: THEOplayer, to handler: PlayerHandler) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: handler.pause),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY, listener: handler.play),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKING, listener: handler.seeking),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKED, listener: handler.seeked),
            player.addRemovableEventListener(type: PlayerEventTypes.DURATION_CHANGE, listener: handler.durationChange),
            player.addRemovableEventListener(type: PlayerEventTypes.WAITING, listener: handler.waiting),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING, listener: handler.playing),
            player.addRemovableEventListener(type: PlayerEventTypes.ENDED, listener: handler.ended),
            player.addRemovableEventListener(type: PlayerEventTypes.DESTROY, listener: handler.onDestroy),
            player.addRemovableEventListener(type: PlayerEventTypes.CURRENT_SOURCE_CHANGE, listener: handler.currentSourceChange),
            player.addRemovableEventListener(type: PlayerEventTypes.ENCRYPTED, listener: handler.encrypted),
            player.addRemovableEventListener(type: PlayerEventTypes.CONTENT_PROTECTION_SUCCESS, listener: handler.contentProtectionSuccess),

            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE) {
                handler.timeUpdate(
                    currentTimeInMilliseconds: $0.currentTimeInMilliseconds,
                    renderedFramerate: NSNumber(value: Int(player.playerMetrics.renderedFramerate.rounded())),
                    droppedFrames: NSNumber(value: player.playerMetrics.droppedVideoFrames)
                )
            },
            player.addRemovableEventListener(type: PlayerEventTypes.SOURCE_CHANGE) {
                handler.sourceChange(event: $0, selectedSource: player.src)
            },
            player.addRemovableEventListener(type: PlayerEventTypes.ERROR) { errorEvent in
                handler.error(event: errorEvent)
            },

            player.videoTracks.addRemovableEventListener(type: VideoTrackListEventTypes.ADD_TRACK) { [weak player] addTrackEvent in
                guard let player else { return }
                handler.videoTrackAdded(event: addTrackEvent, player: player)
            }
        ]
    }    
}
