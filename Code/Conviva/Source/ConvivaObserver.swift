//
//  ConvivaObserver.swift
//  
//
//  Created on 22/06/2023.
//

import THEOplayerSDK
import AVFoundation

class ConvivaObserver {
    private weak var player: THEOplayer?
    private weak var reporter: ConvivaReporter?
    private weak var vpfDetector: ConvivaVPFDetector?
    private var externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol?
    
    // MARK: player event Listeners
    private var playListener: EventListener?
    private var pauseListener: EventListener?
    private var sourceChangeListener: EventListener?
    private var durationChangeListener: EventListener?
    private var timeUpdateListener: EventListener?
    private var playingListener: EventListener?
    private var seekingListener: EventListener?
    private var seekedListener: EventListener?
    private var endedListener: EventListener?
    private var errorListener: EventListener?
    private var waitingListener: EventListener?
    private var destroyListener: EventListener?
    
    // MARK: Network event listeners
    private var networkErrorListener: EventListener?
    
    // MARK: Ad event listeners
    private var adBreakBeginListener: EventListener?
    private var adBreakEndListener: EventListener?
    private var adBeginListener: EventListener?
    private var adEndListener: EventListener?
    private var adErrorListener: EventListener?
    // MARK: external Ad event listeners
    private var externalAdBreakBeginListener: EventListener?
    private var externalAdBreakEndListener: EventListener?
    private var externalAdBeginListener: EventListener?
    private var externalAdEndListener: EventListener?
    private var externalAdErrorListener: EventListener?
    
    // MARK: App observers
    private var foregroundObserver: Any?
    private var backgroundObserver: Any?
    private var accessLogObserver: Any?

    // MARK: init/destroy
    init(player: THEOplayer, reporter: ConvivaReporter, vpfDetector: ConvivaVPFDetector, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol) {
        self.player = player
        self.reporter = reporter
        self.vpfDetector = vpfDetector
        self.externalEventDispatcher = externalEventDispatcher

        self.attachPlayerEventListeners()
        self.attachNetworkEventListeners()
        self.attachAdEventListeners()
        self.attachAppObservers()
        
        self.attachExternalAdEventListeners()
    }
    
    func destroy() {
        self.dettachPlayerEventListeners()
        self.dettachNetworkEventListeners()
        self.dettachAdEventListeners()
        self.dettachAppObservers()
        
        self.dettachExternalAdEventListeners()
    }
    
    // MARK: - attach/dettach Player event Listeners
    private func attachPlayerEventListeners() {
        guard let player = self.player else { return }
        
        // PLAY
        self.playListener = player.addEventListener(type: PlayerEventTypes.PLAY) { [weak self] event in
            self?.reporter?.reportPlay()
        }
        
        // PLAYING
        self.playingListener = player.addEventListener(type: PlayerEventTypes.PLAYING) { [weak self] event in
            self?.reporter?.reportPlaying()
        }
        
        // TIME_UPDATE
        self.timeUpdateListener = player.addEventListener(type: PlayerEventTypes.TIME_UPDATE) { [weak self] event in
            self?.reporter?.reportTimeUpdate(timeInMSec: event.currentTimeInMilliseconds)
            if let frameRate = self?.player?.renderedFramerate {
                self?.reporter?.reportFrameRate(frameRate:  NSNumber(value: Int(frameRate.rounded())))
            }
        }
        
        // PAUSE
        self.pauseListener = player.addEventListener(type: PlayerEventTypes.PAUSE) { [weak self] event in
            self?.reporter?.reportPause()
            if let log = self?.player?.currentItem?.errorLog(),
               let detector = self?.vpfDetector {
                if detector.detectsVPFOnPause(log: log, pauseTime: event.date) {
                    self?.reporter?.reportError(error: "Network Timeout")
                    player.stop()
                }
            }
        }
        
        // WAITING
        self.waitingListener = player.addEventListener(type: PlayerEventTypes.WAITING) { [weak self] event in
            self?.reporter?.reportWaiting()
            self?.vpfDetector?.transitionToWaiting()
        }
        
        // SEEKING
        self.seekingListener = player.addEventListener(type: PlayerEventTypes.SEEKING) { [weak self] event in
            self?.reporter?.reportSeeking(timeInMSec: event.currentTimeInMilliseconds)
        }
        
        // SEEKED
        self.timeUpdateListener = player.addEventListener(type: PlayerEventTypes.SEEKED) { [weak self] event in
            self?.reporter?.reportSeeked(timeInMSec: event.currentTimeInMilliseconds)
        }
        
        // ERROR
        self.errorListener = player.addEventListener(type: PlayerEventTypes.ERROR) { [weak self] event in
            self?.reporter?.reportError(error: event.error)
        }
        
        // SOURCE_CHANGE
        self.sourceChangeListener = player.addEventListener(type: PlayerEventTypes.SOURCE_CHANGE) { [weak self] event in
            self?.reporter?.reportSourceChange(sourceDescription: event.source, selectedUrl: self?.player?.src)
        }
        
        // ENDED
        self.endedListener = player.addEventListener(type: PlayerEventTypes.ENDED) { [weak self] event in
            self?.reporter?.reportEnded()
        }
        
        // DURATION_CHANGE
        self.durationChangeListener = player.addEventListener(type: PlayerEventTypes.DURATION_CHANGE) { [weak self] event in
            self?.reporter?.reportDurationChange(duration: event.duration)
        }
        
        // DESTROY
        self.destroyListener = player.addEventListener(type: PlayerEventTypes.DESTROY) { [weak self] event in
            self?.reporter?.reportDestroy()
        }
    }
    
    private func dettachPlayerEventListeners() {
        guard let player = self.player else {
            return
        }
        
        // PLAY
        if let playListener = self.playListener {
            player.removeEventListener(type: PlayerEventTypes.PLAY, listener: playListener)
        }
        
        // PLAYING
        if let playingListener = self.playingListener {
            player.removeEventListener(type: PlayerEventTypes.PLAYING, listener: playingListener)
        }
        
        // TIME_UPDATE
        if let timeUpdateListener = self.timeUpdateListener {
            player.removeEventListener(type: PlayerEventTypes.TIME_UPDATE, listener: timeUpdateListener)
        }
        
        // PAUSE
        if let pauseListener = self.pauseListener {
            player.removeEventListener(type: PlayerEventTypes.PAUSE, listener: pauseListener)
        }
        
        // WAITING
        if let waitingListener = self.waitingListener {
            player.removeEventListener(type: PlayerEventTypes.WAITING, listener: waitingListener)
        }
        
        // SEEKING
        if let seekingListener = self.seekingListener {
            player.removeEventListener(type: PlayerEventTypes.SEEKING, listener: seekingListener)
        }
        
        // SEEKED
        if let seekedListener = self.seekedListener {
            player.removeEventListener(type: PlayerEventTypes.SEEKED, listener: seekedListener)
        }
        
        // ERROR
        if let errorListener = self.errorListener {
            player.removeEventListener(type: PlayerEventTypes.ERROR, listener: errorListener)
        }
        
        // SOURCE_CHANGE
        if let sourceChangeListener = self.sourceChangeListener {
            player.removeEventListener(type: PlayerEventTypes.SOURCE_CHANGE, listener: sourceChangeListener)
        }
        
        // ENDED
        if let endedListener = self.endedListener {
            player.removeEventListener(type: PlayerEventTypes.ENDED, listener: endedListener)
        }
        
        // DURATION_CHANGE
        if let durationChangeListener = self.durationChangeListener {
            player.removeEventListener(type: PlayerEventTypes.DURATION_CHANGE, listener: durationChangeListener)
        }
        
        // DESTROY
        if let destroyListener = self.destroyListener {
            player.removeEventListener(type: PlayerEventTypes.DESTROY, listener: destroyListener)
        }
    }
    
    // MARK: - attach/dettach Ad event Listeners
    private func attachAdEventListeners() {
        guard let player = self.player, player.hasAdsIntegration else { return }
        
        // AD_BREAK_BEGIN
        self.adBreakBeginListener = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_BEGIN) { [weak self] event in
            if let adBreak = event.ad {
                self?.reporter?.reportAdBreakBegin(adBreak: adBreak)
            }
        }
        
        // AD_BREAK_END
        self.adBreakEndListener = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_END) { [weak self] event in
            self?.reporter?.reportAdBreakEnd()
        }
        
        // AD_BEGIN
        self.adBeginListener = player.ads.addEventListener(type: AdsEventTypes.AD_BEGIN) { [weak self] event in
            if let player = self?.player,
               let duration = player.duration,
               let ad = event.ad,
               ad.type == AdType.linear {
                self?.reporter?.reportAdBegin(ad: ad, duration: duration)
            }
        }
        
        // AD_END
        self.adEndListener = player.ads.addEventListener(type: AdsEventTypes.AD_END) { [weak self] event in
            if let ad = event.ad,
               ad.type == AdType.linear {
                self?.reporter?.reportAdEnd()
            }
        }
        
        // AD_ERROR
        self.adErrorListener = player.ads.addEventListener(type: AdsEventTypes.AD_ERROR) { [weak self] event in
            if let ad = event.ad {
                self?.reporter?.reportAdError(error: event.error ?? "An error occured while playing ad \(ad.id ?? "without id")",
                                              info: ad.convivaInfo)
            } else {
                self?.reporter?.reportAdError(error: event.error ?? "An error occured while playing an ad",
                                              info: nil)
            }
        }
    }
    
    private func dettachAdEventListeners() {
        guard let player = self.player else { return }
        
        // AD_BREAK_BEGIN
        if let adBreakBeginListener = self.adBreakBeginListener {
            player.ads.removeEventListener(type: AdsEventTypes.AD_BREAK_BEGIN, listener: adBreakBeginListener)
        }
        
        // AD_BREAK_END
        if let adBreakEndListener = self.adBreakEndListener {
            player.ads.removeEventListener(type: AdsEventTypes.AD_BREAK_END, listener: adBreakEndListener)
        }
        
        // AD_BEGIN
        if let adBeginListener = self.adBeginListener {
            player.ads.removeEventListener(type: AdsEventTypes.AD_BEGIN, listener: adBeginListener)
        }
        
        // AD_END
        if let adEndListener = self.adEndListener {
            player.ads.removeEventListener(type: AdsEventTypes.AD_END, listener: adEndListener)
        }
        
        // AD_ERROR
        if let adErrorListener = self.adErrorListener {
            player.ads.removeEventListener(type: AdsEventTypes.AD_ERROR, listener: adErrorListener)
        }
    }
    
    // MARK: - attach/dettach external Ad event Listeners
    private func attachExternalAdEventListeners() {
        guard let externalEventDispatcher = self.externalEventDispatcher else { return }
        
        // AD_BREAK_BEGIN
        self.externalAdBreakBeginListener = externalEventDispatcher.addEventListener(type: AdsEventTypes.AD_BREAK_BEGIN) { [weak self] event in
            if let adBreak = event.ad {
                self?.reporter?.reportAdBreakBegin(adBreak: adBreak)
            }
        }
        
        // AD_BREAK_END
        self.externalAdBreakEndListener = externalEventDispatcher.addEventListener(type: AdsEventTypes.AD_BREAK_END) { [weak self] event in
            self?.reporter?.reportAdBreakEnd()
        }
        
        // AD_BEGIN
        self.externalAdBeginListener = externalEventDispatcher.addEventListener(type: AdsEventTypes.AD_BEGIN) { [weak self] event in
            if let player = self?.player,
               let duration = player.duration,
               let ad = event.ad,
               ad.type == AdType.linear {
                self?.reporter?.reportAdBegin(ad: ad, duration: duration)
            }
        }
        
        // AD_END
        self.externalAdEndListener = externalEventDispatcher.addEventListener(type: AdsEventTypes.AD_END) { [weak self] event in
            if let ad = event.ad,
               ad.type == AdType.linear {
                self?.reporter?.reportAdEnd()
            }
        }
        
        // AD_ERROR
        self.externalAdErrorListener = externalEventDispatcher.addEventListener(type: AdsEventTypes.AD_ERROR) { [weak self] event in
            if let ad = event.ad {
                self?.reporter?.reportAdError(error: event.error ?? "An error occured while playing ad \(ad.id ?? "without id")",
                                              info: ad.convivaInfo)
            } else {
                self?.reporter?.reportAdError(error: event.error ?? "An error occured while playing an ad",
                                              info: nil)
            }
        }
    }
    
    private func dettachExternalAdEventListeners() {
        guard let externalEventDispatcher = self.externalEventDispatcher else { return }
        
        // AD_BREAK_BEGIN
        if let adBreakBeginListener = self.externalAdBreakBeginListener {
            externalEventDispatcher.removeEventListener(type: AdsEventTypes.AD_BREAK_BEGIN, listener: adBreakBeginListener)
        }
        
        // AD_BREAK_END
        if let adBreakEndListener = self.externalAdBreakEndListener {
            externalEventDispatcher.removeEventListener(type: AdsEventTypes.AD_BREAK_END, listener: adBreakEndListener)
        }
        
        // AD_BEGIN
        if let adBeginListener = self.externalAdBeginListener {
            externalEventDispatcher.removeEventListener(type: AdsEventTypes.AD_BEGIN, listener: adBeginListener)
        }
        
        // AD_END
        if let adEndListener = self.externalAdEndListener {
            externalEventDispatcher.removeEventListener(type: AdsEventTypes.AD_END, listener: adEndListener)
        }
        
        // AD_ERROR
        if let adErrorListener = self.externalAdErrorListener {
            externalEventDispatcher.removeEventListener(type: AdsEventTypes.AD_ERROR, listener: adErrorListener)
        }
    }
    
    // MARK: - attach/dettach Network event Listeners
    private func attachNetworkEventListeners() {
        guard let player = self.player else { return }
        
        // NETWORK ERROR
        self.networkErrorListener = player.network.addEventListener(type: NetworkEventTypes.ERROR) { [weak self] event in
            self?.reporter?.reportNetworkError(error: event.error?.message ?? Utilities.defaultStringValue)
        }
    }
    
    private func dettachNetworkEventListeners() {
        guard let player = self.player else { return }
        
        // NETWORK ERROR
        if let networkErrorListener = self.networkErrorListener {
            player.network.removeEventListener(type: NetworkEventTypes.ERROR, listener: networkErrorListener)
        }
    }
    
    // MARK: - attach/dettach App observers
    private func attachAppObservers() {
        self.foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                         object: .none,
                                                                         queue: .none,
                                                                         using: { notification in
            self.reporter?.reportAppWillenterForeground()
            
        })
        self.backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                         object: .none,
                                                                         queue: .none,
                                                                         using: { notification in
            self.reporter?.reportAppDidenterBackground()
            
        })
        self.accessLogObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemNewAccessLogEntry,
                                                                         object: .none,
                                                                         queue: .none,
                                                                         using: { notification in
            guard let item = notification.object as? AVPlayerItem,
                  let event = item.accessLog()?.events.last,
                  let player = self.player,
                  item == player.currentItem else {
                return
            }
            if event.indicatedBitrate >= 0 {
                self.reporter?.reportBitRate(kbps: NSNumber(value: event.indicatedBitrate / 1000))
            }
            if (event.numberOfDroppedVideoFrames >= 0) {
                self.reporter?.reportDroppedFrames(count: NSNumber(value: event.numberOfDroppedVideoFrames))
            }
        })
    }
    
    private func dettachAppObservers() {
        if let foregroundObserver = self.foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver, name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        if let backgroundObserver = self.backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver, name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        if let accessLogObserver = self.accessLogObserver {
            NotificationCenter.default.removeObserver(accessLogObserver, name: NSNotification.Name.AVPlayerItemNewAccessLogEntry, object: nil)
        }
    }
}
