//
//  BasicEventObserver.swift
//  
//
//  Created by Damiaan Dufaux on 01/09/2022.
//

import THEOplayerSDK
import THEOplayerConnectorUtilities

/// A handle that registers basic playback listeners on a theoplayer and removes them on deinit
struct BasicEventForwarder {
    let observer: DispatchObserver
    let textTrackObserver: DispatchObserver

    init(player: THEOplayer, eventProcessor: BasicEventProcessor) {
        observer = .init(
            dispatcher: player,
            eventListeners: Self.forwardEvents(from: player, to: eventProcessor)
        )
        textTrackObserver = .init(
            dispatcher: player.textTracks,
            eventListeners: Self.forwardID3Events(from: player.textTracks, to: eventProcessor)
        )
    }
    
    static func forwardEvents(from player: THEOplayer, to processor: BasicEventProcessor) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY) {
                processor.play(event: $0, selectedSource: player.src)
            },
            player.addRemovableEventListener(type: PlayerEventTypes.LOADED_META_DATA) {
                processor.loadedMetadata(event: $0, duration: player.duration)
            },
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING, listener: processor.playing),
            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE, listener: processor.timeUpdate),
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: processor.pause),
            player.addRemovableEventListener(type: PlayerEventTypes.SOURCE_CHANGE) {
                processor.sourceChange(event: $0, selectedSource: player.src)
            },
            player.addRemovableEventListener(type: PlayerEventTypes.ENDED, listener: processor.ended),
            player.addRemovableEventListener(type: PlayerEventTypes.DESTROY, listener: processor.destroy),
        ]
    }
    
    static func forwardID3Events(from textTracks: TextTrackList, to processor: BasicEventProcessor) -> [RemovableEventListenerProtocol] {
        var observers = [Int: DispatchObserver]()
        return [
            textTracks.addRemovableEventListener(type: TextTrackListEventTypes.ADD_TRACK) { addition in
                if let track = addition.track as? TextTrack, track.type == "id3" {
                    observers[track.uid] = DispatchObserver(
                        dispatcher: track,
                        eventListeners: [track.addRemovableEventListener(type: TextTrackEventTypes.ENTER_CUE, listener: processor.cueEnter)]
                    )
                }
            },
            textTracks.addRemovableEventListener(type: TextTrackListEventTypes.REMOVE_TRACK, listener: { event in
                observers.removeValue(forKey: event.track.uid)
            })
        ]
    }
}

/// An entity that processes basic playback events from a THEOplayer
protocol BasicEventProcessor {
    func play(event: PlayEvent, selectedSource: String?)
    func loadedMetadata(event: LoadedMetaDataEvent, duration: Double?)
    func playing(event: PlayingEvent)
    func timeUpdate(event: TimeUpdateEvent)
    func pause(event: PauseEvent)
    func sourceChange(event: SourceChangeEvent, selectedSource: String?)
    func ended(event: EndedEvent)
    func destroy(event: DestroyEvent)
    func cueEnter(event: EnterCueEvent)
}
