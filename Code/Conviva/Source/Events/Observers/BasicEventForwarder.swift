//
//  BasicEventForwarder.swift
//  

import THEOplayerSDK
import THEOplayerConnectorUtilities
import AVFoundation

/// A handle that registers basic playback listeners on a theoplayer and removes them on deinit
class BasicEventForwarder: VPFDetectordelegate {
    private let playerObserver: DispatchObserver
    private let networkObserver: DispatchObserver
    weak var player: THEOplayer?
    weak var vpfDetector: ConvivaVPFDetector?
    weak var eventProcessor: BasicEventConvivaReporter?
    
    init(player: THEOplayer, vpfDetector: ConvivaVPFDetector, eventProcessor: BasicEventConvivaReporter) {
        playerObserver = .init(
            dispatcher: player,
            eventListeners: Self.forwardEvents(from: player, vpfDetector: vpfDetector, to: eventProcessor)
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
        
        // set self as delegate for VPF detection
        vpfDetector.delegate = self
        self.vpfDetector = vpfDetector
    }
    
    func destroy() {
        self.vpfDetector?.reset()
    }
    
    static func forwardEvents(from player: THEOplayer, vpfDetector: ConvivaVPFDetector, to processor: BasicEventConvivaReporter) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: processor.pause),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY, listener: processor.play),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKING, listener: processor.seeking),
            player.addRemovableEventListener(type: PlayerEventTypes.SEEKED, listener: processor.seeked),
            player.addRemovableEventListener(type: PlayerEventTypes.DURATION_CHANGE, listener: processor.durationChange),
            
            // relating to VPF detection
            player.addRemovableEventListener(type: PlayerEventTypes.WAITING) {
                processor.waiting(event: $0)
                vpfDetector.transitionToWaiting()       // start stall monitoring
            },
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING) {
                processor.playing(event: $0)
                vpfDetector.reset()                     // stall resolved
            },
            player.addRemovableEventListener(type: PlayerEventTypes.PROGRESS) { _ in
                vpfDetector.reset()                     // stall resolved
            },
            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE) {
                processor.timeUpdate(event: $0)
                if let rate = player.renderedFramerate {
                    processor.renderedFramerateUpdate(framerate: rate)
                }
            },
            player.addRemovableEventListener(type: PlayerEventTypes.SOURCE_CHANGE) {
                processor.sourceChange(event: $0, selectedSource: player.src)
                vpfDetector.reset()                     // playback ended
            },
            player.addRemovableEventListener(type: PlayerEventTypes.ERROR) {
                processor.error(event: $0)
                vpfDetector.reset()                     // playback ended
            },
            player.addRemovableEventListener(type: PlayerEventTypes.ENDED) {
                processor.ended(event: $0)
                vpfDetector.reset()                     // playback ended
            },
            player.addRemovableEventListener(type: PlayerEventTypes.DESTROY) {
                processor.destroy(event: $0)
                vpfDetector.reset()                     // playback ended
            }
        ]
    }
    
    func onVPFDetected() {
        self.reportFatalError(message: "Network Error")
        self.player?.stop()
    }
    
    func reportFatalError(message: String, errorObject: THEOplayerSDK.THEOError? = nil, date: Date = Date()) {
        self.eventProcessor?.error(event: ErrorEvent(error: message, errorObject: errorObject, date: date))
    }
}
