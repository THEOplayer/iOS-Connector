//
//  ViewController.swift
//  SideloadedTextTracksExample
//
//  Created by Wonne Joosen on 13/04/2024.
//

import UIKit
import THEOplayerSDK
import THEOplayerConnectorUplynk
import os

class ViewController: UIViewController {
    private(set) var player: THEOplayer!
    private var uplynkConnector: UplynkConnector!
    
    // View contains custom player interface
    private var playerInterfaceView: PlayerInterfaceView!
    // Dictionary of player event listeners
    var listeners: [String: EventListener] = [:]

    
    @IBOutlet weak var playerStackView: UIStackView!
    @IBOutlet weak var playerViewContainer: UIView!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var sourceSegmentedControl: UISegmentedControl!
    @IBOutlet weak var skipStrategySegmentedControl: UISegmentedControl!
    @IBOutlet weak var adsConfigurationStackView: UIStackView!
    @IBOutlet weak var skipOffsetValue: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        resetState()
        setupPlayerView()
    }
    
    func resetState() {
        activityIndicatorView.stopAnimating()
        skipOffsetValue.text = "\(Int(stepper.value))"
        skipStrategySegmentedControl.selectedSegmentIndex = 0
        adsConfigurationStackView.isHidden = sourceSegmentedControl.selectedSegmentIndex != 1 && sourceSegmentedControl.selectedSegmentIndex != 3
    }
    
    private var selectedSkipStrategy: SkippedAdStrategy {
        switch skipStrategySegmentedControl.selectedSegmentIndex {
        case 1:
            return .playAll
        case 2:
            return .playLast
        default:
            return .playNone
        }
    }
    
    private var selectedSkipOffsetValue: Int {
        Int(stepper.value)
    }
    
    private var adPlaying: Bool {
        if player.ads.playing {
            return true
        }
        return false
    }
    
    private func setupPlayerView() {
        playerViewContainer.subviews.forEach {
            if $0 is PlayerView {
                $0.removeFromSuperview()
            }
        }
        let configBuilder = THEOplayerConfigurationBuilder()
        configBuilder.license = "your licence"
        player = THEOplayer(with: nil, 
                            configuration: configBuilder.build())

        let playerView = PlayerView(player: player)
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.frame = playerViewContainer.bounds
        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerViewContainer.addSubview(playerView)
        
        configureUplynkConnector()
        setupPlayerInterfaceView()
        addAdsEventListeners()
        attachPlayerEventListeners()
        
    }
    
    private func configureUplynkConnector() {
        uplynkConnector = UplynkConnector(player: player,
                                          configuration: .init(defaultSkipOffset: selectedSkipOffsetValue,
                                                               skippedAdStrategy: selectedSkipStrategy),
                                          eventListener: self)
        setupSource()
    }
    
    private func setupPlayerInterfaceView() {
        playerViewContainer.subviews.forEach {
            if $0 is PlayerInterfaceView {
                $0.removeFromSuperview()
            }
        }
        let playerInterfaceView = PlayerInterfaceView()
        playerInterfaceView.delegate = self
        playerInterfaceView.state = .initialise

        playerViewContainer.addSubview(playerInterfaceView)

        playerInterfaceView.leadingAnchor.constraint(equalTo: playerViewContainer.leadingAnchor).isActive = true
        playerInterfaceView.trailingAnchor.constraint(equalTo: playerViewContainer.trailingAnchor).isActive = true
        playerInterfaceView.topAnchor.constraint(equalTo: playerViewContainer.topAnchor).isActive = true
        playerInterfaceView.bottomAnchor.constraint(equalTo: playerViewContainer.bottomAnchor).isActive = true

        // Ensure interface is the top subview of theoplayerView
        playerViewContainer.insertSubview(playerInterfaceView, at: playerViewContainer.subviews.count)
        self.playerInterfaceView = playerInterfaceView
    }
    
    private func setupSource() {
        switch sourceSegmentedControl.selectedSegmentIndex {
        case 0:
            player.source = .live
        case 1:
             player.source = .ads
        case 2:
            player.source = .multiDRM
        default:
            // No-op
            break
        }
    }
    
    private func attachPlayerEventListeners() {
        // Listen to event and store references in dictionary
        listeners["play"] = player.addEventListener(type: PlayerEventTypes.PLAY, listener: { [weak self] event in self?.onPlay(event: event) })
        listeners["playing"] = player.addEventListener(type: PlayerEventTypes.PLAYING, listener: { [weak self] event in self?.onPlaying(event: event) })
        listeners["pause"] = player.addEventListener(type: PlayerEventTypes.PAUSE, listener: { [weak self] event in self?.onPause(event: event) })
        listeners["ended"] = player.addEventListener(type: PlayerEventTypes.ENDED, listener: { [weak self] event in self?.onEnded(event: event) })
        listeners["error"] = player.addEventListener(type: PlayerEventTypes.ERROR, listener: { [weak self] event in self?.onError(event: event) })

        listeners["sourceChange"] = player.addEventListener(type: PlayerEventTypes.SOURCE_CHANGE, listener: { [weak self] event in self?.onSourceChange(event: event) })
        listeners["readyStateChange"] = player.addEventListener(type: PlayerEventTypes.READY_STATE_CHANGE, listener: { [weak self] event in self?.onReadyStateChange(event: event) })
        listeners["waiting"] = player.addEventListener(type: PlayerEventTypes.WAITING, listener: { [weak self] event in self?.onWaiting(event: event) })
        listeners["seeking"] = player.addEventListener(type: PlayerEventTypes.SEEKING, listener: { [weak self] event in self?.onSeeking(event: event) })
        listeners["seeked"] = player.addEventListener(type: PlayerEventTypes.SEEKED, listener: { [weak self] event in self?.onSeeked(event: event) })
        listeners["loadedData"] = player.addEventListener(type: PlayerEventTypes.LOADED_DATA, listener: { [weak self] event in self?.onLoadedData(event: event) })
        listeners["loadedMetadata"] = player.addEventListener(type: PlayerEventTypes.LOADED_META_DATA, listener: { [weak self] event in self?.onLoadedMetadata(event: event) })
        listeners["durationChange"] = player.addEventListener(type: PlayerEventTypes.DURATION_CHANGE, listener: { [weak self] event in self?.onDurationChange(event: event) })
        listeners["timeUpdate"] = player.addEventListener(type: PlayerEventTypes.TIME_UPDATE, listener: { [weak self] event in self?.onTimeUpdate(event: event) })
        listeners["presentationModeChange"] = player.addEventListener(type: PlayerEventTypes.PRESENTATION_MODE_CHANGE, listener: { [weak self] event in self?.onPresentationModeChange(event: event) })

        listeners["adBreakBegin"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_BEGIN, listener: { [weak self] event in self?.onAdBreakBegin(event: event) })
        listeners["adBreakEnd"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_END, listener: { [weak self] event in self?.onAdBreakEnd(event: event) })
    }
    
    private func onPlay(event: PlayEvent) {
        os_log("PLAY event, currentTime: %f", event.currentTime)
        if self.playerInterfaceView.state == .initialise {
            self.playerInterfaceView.state = .buffering
        }
        if self.adPlaying {
            self.playerInterfaceView.state = .adplaying
        }
    }

    private func onPlaying(event: PlayingEvent) {
        os_log("PLAYING event, currentTime: %f", event.currentTime)
        if self.adPlaying {
            self.playerInterfaceView.state = .adplaying
        } else {
            self.playerInterfaceView.state = .playing
        }
    }

    private func onPause(event: PauseEvent) {
        os_log("PAUSE event, currentTime: %f", event.currentTime)
        // Pause might be triggered when Application goes into background which should be ignored if playback is not started yet
        if self.playerInterfaceView.state != .initialise {
            self.playerInterfaceView.state = self.adPlaying ? .adpaused : .paused
        }
    }

    private func onEnded(event: EndedEvent) {
        os_log("ENDED event, currentTime: %f", event.currentTime)
        // Stop player
        player.stop()
        
        setupSource()
    }

    private func onError(event: ErrorEvent) {
        os_log("ERROR event, error: %@", event.error)
    }

    private func onSourceChange(event: SourceChangeEvent) {
        os_log("SOURCE_CHANGE event, url: %@", event.source?.sources[0].src.absoluteString ?? "")
        // Initialise UI on source change
        self.playerInterfaceView.state = .initialise
    }

    private func onReadyStateChange(event: ReadyStateChangeEvent) {
        os_log("READY_STATE_CHANGE event, state: %d", event.readyState.rawValue)
    }

    private func onWaiting(event: WaitingEvent) {
        os_log("WAITING event, currentTime: %f", event.currentTime)
        // Waiting event indicates there is not enough data to play, hence the buffering state
        self.playerInterfaceView.state = .buffering
    }
    
    private func onSeeking(event: SeekingEvent) {
        os_log("SEEKING event, currentTime: %f", event.currentTime)
    }
    
    private func onSeeked(event: SeekedEvent) {
        os_log("SEEKED event, currentTime: %f", event.currentTime)
    }
    
    private func onLoadedData(event: LoadedDataEvent) {
        os_log("LOADEDDATA event")
    }
    
    private func onLoadedMetadata(event: LoadedMetaDataEvent) {
        os_log("LOADEDMETADATA event")
    }

    private func onDurationChange(event: DurationChangeEvent) {
        os_log("DURATION_CHANGE event, duration: %f", event.duration ?? 0.0)
        // Set UI duration
        if let duration: Double = event.duration,
           duration.isNormal {
            self.playerInterfaceView.duration = Float(duration)
        }
    }

    private func onTimeUpdate(event: TimeUpdateEvent) {
        os_log("TIME_UPDATE event, currentTime: %f", event.currentTime)
        // Update UI current time
        if !player.seeking {
            self.playerInterfaceView.currentTime = Float(event.currentTime)
        }
    }

    private func onPresentationModeChange(event: PresentationModeChangeEvent) {
        os_log("PRESENTATION_MODE_CHANGE event, presentationMode: %d", event.presentationMode.rawValue)
    }

    private func onAdBreakBegin(event: AdBreakBeginEvent) {
        os_log("AD_BREAK_BEGIN event")
        self.playerInterfaceView.state = .adplaying
    }

    private func onAdBreakEnd(event: AdBreakEndEvent) {
        os_log("AD_BREAK_END event")
        self.playerInterfaceView.state = .playing
    }

    @IBAction func onChangeSource(_ sender: Any) {
        stop()
        resetState()
        setupPlayerView()
    }

    @IBAction func onChangeSkipOffset(_ sender: Any) {
        stop()
        skipOffsetValue.text = "\(Int(stepper.value))"
        setupPlayerView()
    }
    
    @IBAction func onChangeSkipStrategySelection(_ sender: Any) {
        stop()
        setupPlayerView()
    }
        
    @IBAction func skipAd(_ sender: Any) {
        self.player.ads.skip()
    }
    
    private func stop() {
        player.stop()
    }
    
    private func startLoading() {
        activityIndicatorView.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    private func stopLoading() {
        activityIndicatorView.stopAnimating()
        view.isUserInteractionEnabled = true
    }
}

// MARK: - PlayerInterfaceViewDelegate

extension ViewController: PlayerInterfaceViewDelegate {
    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func skip(isForward: Bool) {
        var newTime: Double = player.currentTime + (isForward ? 10 : -10)
        // Make sure newTime is not less than 0
        newTime = newTime < 0 ? 0 : newTime
        if let duration: Double = player.duration {
            // Make sure newTime is not bigger than duration
            newTime = newTime > duration ? duration : newTime
        }
        self.seek(timeInSeconds: Float(newTime))
    }

    func seek(timeInSeconds: Float) {
        // Set current time will trigger waiting event
        player.currentTime = Double(timeInSeconds)
        self.playerInterfaceView.currentTime = timeInSeconds
    }
}


extension ViewController: UplynkEventListener {
    func onPreplayLiveResponse(_ response: THEOplayerConnectorUplynk.PrePlayLiveResponse) {
        // no-op
    }
    
    func onPreplayVODResponse(_ response: THEOplayerConnectorUplynk.PrePlayVODResponse) {
        // no-op
    }
    
    func onAssetInfoResponse(_ response: THEOplayerConnectorUplynk.AssetInfoResponse) {
        print("Asset Info: \(String(describing: response))")
    }
    
    func onPingResponse(_ response: THEOplayerConnectorUplynk.PingResponse) {
        // no-op
    }
    
    func onError(_ error: THEOplayerConnectorUplynk.UplynkError) {
        print("Error Occured: { url: \(error.url), description: \(error.localizedDescription)")
    }
}
