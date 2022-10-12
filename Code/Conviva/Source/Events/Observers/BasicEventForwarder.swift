//
//  BasicEventForwarder.swift
//  
//
//  Created by Damiaan Dufaux on 01/09/2022.
//

import THEOplayerSDK

/// A handle that registers basic playback listeners on a theoplayer and removes them on deinit
struct BasicEventForwarder {
    let observer: DispatchObserver
    
    init(player: THEOplayer, eventProcessor: BasicEventProcessor) {
        observer = .init(
            dispatcher: player,
            eventListeners: Self.forwardEvents(from: player, to: eventProcessor)
        )
    }
    
    static func forwardEvents(from player: THEOplayer, to processor: BasicEventProcessor) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY, listener: processor.play),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING, listener: processor.playing),
            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE, listener: processor.timeUpdate),
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: processor.pause),
            player.addRemovableEventListener(type: PlayerEventTypes.WAITING, listener: processor.waiting),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKING, listener: processor.seeking),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKED, listener: processor.seeked),
            player.addRemovableEventListener(type: PlayerEventTypes.ERROR, listener: processor.error),
            player.addRemovableEventListener(type: PlayerEventTypes.SOURCE_CHANGE) {
                processor.sourceChange(event: $0, selectedSource: player.src)
            },
            player.addRemovableEventListener(type: PlayerEventTypes.ENDED, listener: processor.ended),
            player.addRemovableEventListener(type: PlayerEventTypes.DURATION_CHANGE, listener: processor.durationChange),
            player.addRemovableEventListener(type: PlayerEventTypes.DESTROY, listener: processor.destroy),
        ]
    }
}

/// An entity that processes basic playback events from a THEOplayer
protocol BasicEventProcessor {
    func play(event: PlayEvent)
    func playing(event: PlayingEvent)
    func timeUpdate(event: TimeUpdateEvent)
    func pause(event: PauseEvent)
 // func empty() // TODO: add this event
    func waiting(event: WaitingEvent)
    func seeking(event: SeekingEvent)
    func seeked(event: SeekedEvent)
    func error(event: ErrorEvent)
 // func segmentNotFound() // TODO: add this event
    func sourceChange(event: SourceChangeEvent, selectedSource: String?)
    func ended(event: EndedEvent)
    func durationChange(event: DurationChangeEvent)
    func destroy(event: DestroyEvent)
}
