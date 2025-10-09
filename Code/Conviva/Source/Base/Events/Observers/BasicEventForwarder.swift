//
//  BasicEventForwarder.swift
//  

import THEOplayerSDK
import THEOplayerConnectorUtilities
import AVFoundation

/// A handle that registers basic playback listeners on a theoplayer and removes them on deinit
class BasicEventForwarder {
    private let playerObserver: DispatchObserver
    private let networkObserver: DispatchObserver
    weak var player: THEOplayer?
    weak var eventProcessor: BasicEventConvivaReporter?
    
    init(player: THEOplayer, eventProcessor: BasicEventConvivaReporter) {
        playerObserver = .init(
            dispatcher: player,
            eventListeners: Self.forwardEvents(from: player, to: eventProcessor)
        )
        networkObserver = .init(
            dispatcher: player.network,
            eventListeners: [
                player.network.addRemovableEventListener(
                    type: NetworkEventTypes.ERROR,
                    listener: eventProcessor.networkError
                )
            ]
        )
        
        // store weak references to process detected VPF.
        self.player = player
        self.eventProcessor = eventProcessor
    }
    
    static func forwardEvents(from player: THEOplayer, to processor: BasicEventConvivaReporter) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: processor.pause),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY, listener: processor.play),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKING, listener: processor.seeking),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKED, listener: processor.seeked),
            player.addRemovableEventListener(type: PlayerEventTypes.DURATION_CHANGE, listener: processor.durationChange),
            player.addRemovableEventListener(type: PlayerEventTypes.WAITING, listener: processor.waiting),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING, listener: processor.playing),
            player.addRemovableEventListener(type: PlayerEventTypes.ENDED, listener: processor.ended),
            player.addRemovableEventListener(type: PlayerEventTypes.DESTROY, listener: processor.onDestroy),
            player.addRemovableEventListener(type: PlayerEventTypes.CURRENT_SOURCE_CHANGE, listener: processor.currentSourceChange),
            player.addRemovableEventListener(type: PlayerEventTypes.ENCRYPTED, listener: processor.encrypted),
            player.addRemovableEventListener(type: PlayerEventTypes.CONTENT_PROTECTION_SUCCESS, listener: processor.contentProtectionSuccess),

            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE) {
                processor.timeUpdate(event: $0)
                if let rate = player.renderedFramerate {
                    processor.renderedFramerateUpdate(framerate: rate)
                }
            },
            player.addRemovableEventListener(type: PlayerEventTypes.SOURCE_CHANGE) {
                processor.sourceChange(event: $0, selectedSource: player.src)
            },
            player.addRemovableEventListener(type: PlayerEventTypes.ERROR) { errorEvent in
                processor.error(event: errorEvent)
            },

            player.videoTracks.addRemovableEventListener(type: VideoTrackListEventTypes.ADD_TRACK) { [weak player] addTrackEvent in
                guard let player else { return }
                processor.videoTrackAdded(event: addTrackEvent, player: player)
            }
        ]
    }    
}
