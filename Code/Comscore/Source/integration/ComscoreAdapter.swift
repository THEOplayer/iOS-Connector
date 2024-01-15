//
//  ComscoreAdapter.swift
//
//  Copyright © THEOPlayer. All rights reserved.
//

import Foundation
import ComScore
import THEOplayerSDK

enum ComScoreState: String {
    case initialized = "INITIALIZED"
    case stopped = "STOPPED"
    case paused_ad = "PAUSED_AD"
    case paused_video = "PAUSED_VIDEO"
    case advertisement = "ADVERTISEMENT"
    case video = "VIDEO"
}

class THEOComScoreAdapter: NSObject {
    // MARK: - Member variables
    private var comscoreMetadata : ComScoreMetadata
    private var comscoreState: ComScoreState = .initialized
    private let configuration: ComScoreConfiguration
    private var currentAdId: String = "-1"
    private var currentAdDuration: Int = 0
    private var currentAdOffset: Int = 0
    private var currentContentMetadata: SCORStreamingContentMetadata?
    private var inAd: Bool = false
    private var isBuffering: Bool = false
    private var isSeeking: Bool = false
    private let player: THEOplayer
    private let playerVersion: String
    private let streamingAnalytics = SCORStreamingAnalytics()
    private var justRestarted: Bool = false
    
    private var currentVideoduration: Double = 0.0
    private var listeners: [String: EventListener] = [:]
    
    private let accessQueue = DispatchQueue(label: "ComScoreQueue", attributes: .concurrent)


    // MARK: - Public methods and constructor

    init(player: THEOplayer, playerVersion: String, configuration: ComScoreConfiguration, metadata: ComScoreMetadata) {
        self.player = player
        self.playerVersion = playerVersion
        self.configuration = configuration
        self.comscoreMetadata = metadata
        super.init()
        self.attachEventListeners()
        
        streamingAnalytics.setMediaPlayerName("THEOplayer")
        streamingAnalytics.setMediaPlayerVersion(playerVersion)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        THEOLog.isEnabled = configuration.debug
    }

    deinit {
        if configuration.debug { print("[THEOplayerConnectorComscore] Calling adapter destroy due to deinit") }
        destroy()
    }
    
    func update(metadata: ComScoreMetadata) {
        self.comscoreMetadata = metadata
        self.currentContentMetadata = nil
    }
    
    public func toPaused() {
        transitionToPaused()
    }
    
    public func setPersistentLabel(label: String, value: String) {
        notifyHiddenEvent(publisherId: self.configuration.publisherId, label: label, value: value)
        if configuration.debug { print("[THEOplayerConnectorComscore] ComScore persistent label set: [\(label):\(value)]") }
    }

    public func setPersistentLabels(labels: [String: String]) {
        notifyHiddenEvents(publisherId: self.configuration.publisherId, labels: labels)
        if configuration.debug { print("[THEOplayerConnectorComscore] ComScore persistent labels set: [\(labels.map { "\($0.key):\($0.value)"})]") }
    }
    
    private func attachEventListeners() {
        // Listen to event and store references in dictionary
        listeners["adbreakBegin"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_BEGIN, listener: onAdbreakBegin)
        listeners["adbreakEnd"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_END, listener: onAdbreakEnd)
        listeners["adBegin"] = player.ads.addEventListener(type: AdsEventTypes.AD_BEGIN, listener: onAdBegin)
        listeners["destroy"] = player.addEventListener(type: PlayerEventTypes.DESTROY, listener: onDestroy)
        listeners["ended"] = player.addEventListener(type: PlayerEventTypes.ENDED, listener: onEnded)
        if configuration.debug { print("[THEOplayerConnectorComscore] added the ended listener") }
        listeners["error"] = player.addEventListener(type: PlayerEventTypes.ERROR, listener: onError)
        listeners["loadedmetadata"] = player.addEventListener(type: PlayerEventTypes.LOADED_META_DATA, listener: onLoadedMetadata)
        listeners["pause"] = player.addEventListener(type: PlayerEventTypes.PAUSE, listener: onPause)
        listeners["playbackRateChanged"] = player.addEventListener(type: PlayerEventTypes.RATE_CHANGE, listener: onPlaybackRatechange)
        listeners["playing"] = player.addEventListener(type: PlayerEventTypes.PLAYING, listener: onPlaying)
        listeners["seeked"] = player.addEventListener(type: PlayerEventTypes.SEEKED, listener: onSeeked)
        listeners["seeking"] = player.addEventListener(type: PlayerEventTypes.SEEKING, listener: onSeeking)
        listeners["sourceChange"] = player.addEventListener(type: PlayerEventTypes.SOURCE_CHANGE, listener: onSourceChange)
        listeners["waiting"] = player.addEventListener(type: PlayerEventTypes.WAITING, listener: onWaiting)
    }

    private func removeEventListeners() {
        // Remove event listeners
        if let adBreakBeginListener = listeners["adbreakBegin"] {
            player.ads.removeEventListener(type: AdsEventTypes.AD_BREAK_BEGIN, listener: adBreakBeginListener)
        }
        if let adbreakEndListener = listeners["adbreakEnd"] {
            player.ads.removeEventListener(type: AdsEventTypes.AD_BREAK_END, listener: adbreakEndListener)
        }
        
        if let adBeginListener = listeners["adBegin"] {
            player.ads.removeEventListener(type: AdsEventTypes.AD_BEGIN, listener: adBeginListener)
        }
        
        if let destroyListener = listeners["destroy"] {
            player.removeEventListener(type: PlayerEventTypes.DESTROY, listener: destroyListener)
        }
        
        if let endedListener = listeners["ended"] {
            player.removeEventListener(type: PlayerEventTypes.ENDED, listener: endedListener)
        }
        
        if let errorListener = listeners["error"] {
            player.removeEventListener(type: PlayerEventTypes.ERROR, listener: errorListener)
        }
        
        if let loadedmetadataListener = listeners["loadedmetadata"] {
            player.removeEventListener(type: PlayerEventTypes.LOADED_META_DATA, listener: loadedmetadataListener)
        }
        
        if let pauseListener = listeners["pause"] {
            player.removeEventListener(type: PlayerEventTypes.PAUSE, listener: pauseListener)
        }
        
        if let playbackRateChangedListener = listeners["playbackRateChanged"] {
            player.removeEventListener(type: PlayerEventTypes.RATE_CHANGE, listener: playbackRateChangedListener)
        }
        
        if let playingListener = listeners["playing"] {
            player.removeEventListener(type: PlayerEventTypes.PLAYING, listener: playingListener)
        }
        
        if let seekedListener = listeners["seeked"] {
            player.removeEventListener(type: PlayerEventTypes.SEEKED, listener: seekedListener)
        }
        
        if let seekingListener = listeners["seeking"] {
            player.removeEventListener(type: PlayerEventTypes.SEEKING, listener: seekingListener)
        }
        
        if let sourceChangeListener = listeners["sourceChange"] {
            player.removeEventListener(type: PlayerEventTypes.SOURCE_CHANGE, listener: sourceChangeListener)
        }
        
        if let waitingListener = listeners["waiting"] {
            player.removeEventListener(type: PlayerEventTypes.WAITING, listener: waitingListener)
        }
        listeners.removeAll()
    }
    
    // MARK: - Building and setting metadata
    private func setAdMetadata() {
        if configuration.debug { print("[THEOplayerConnectorComscore] setting ad metadata with ad duration ", currentAdDuration, " and ad offset ", currentAdOffset) }
        var advertisementType: SCORStreamingAdvertisementType
        if (comscoreMetadata.length == 0) {
            advertisementType = .live
        } else if (currentAdOffset == 0) {
            advertisementType = .onDemandPreRoll
        } else if (currentAdOffset < 0) {
            advertisementType = .onDemandPostRoll
        } else {
            advertisementType = .onDemandMidRoll
        }
        
        if self.currentContentMetadata == nil {
            buildContentMetadata()
        }
        
        let advertisementMetadata = SCORStreamingAdvertisementMetadata {builder in
            builder?.setMediaType(advertisementType)
            builder?.setUniqueId(self.currentAdId)
            builder?.setLength(self.currentAdDuration)
            builder?.setRelatedContentMetadata(self.currentContentMetadata)
        }
        streamingAnalytics.setMetadata(advertisementMetadata)
    }
    
    private func setContentMetadata() {
        if configuration.debug { print("[THEOplayerConnectorComscore] setting content metadata with duration ", comscoreMetadata.length) }
        if self.currentContentMetadata == nil {
            buildContentMetadata()
        }
        streamingAnalytics.setMetadata(currentContentMetadata)
    }
    
    func buildContentMetadata() {
        let contentMetadata = SCORStreamingContentMetadata { (builder) in
            builder?.setMediaType(self.comscoreMetadata.mediaType)
            builder?.setUniqueId(self.comscoreMetadata.uniqueId)
            builder?.setLength(self.comscoreMetadata.length)
            if let c3 = self.comscoreMetadata.c3 {
                builder?.setDictionaryClassificationC3(c3)
            }
            if let c4 = self.comscoreMetadata.c4 {
                builder?.setDictionaryClassificationC4(c4)
            }
            if let c6 = self.comscoreMetadata.c6 {
                builder?.setDictionaryClassificationC6(c6)
            }
            builder?.setStationTitle(self.comscoreMetadata.stationTitle)
            if let stationCode = self.comscoreMetadata.stationCode {
                builder?.setStationCode(stationCode)
            }
            if let networkAffiliate = self.comscoreMetadata.networkAffiliate {
                builder?.setNetworkAffiliate(networkAffiliate)
            }
            if let publisherName = self.comscoreMetadata.publisherName {
                builder?.setPublisherName(publisherName)
            }
            builder?.setProgramTitle(self.comscoreMetadata.programTitle)
            if let programId = self.comscoreMetadata.programId {
                builder?.setProgramId(programId)
            }
            builder?.setEpisodeTitle(self.comscoreMetadata.episodeTitle)
            if let episodeId = self.comscoreMetadata.episodeId {
                builder?.setEpisodeId(episodeId)
            }
            if let episodeSeasonNumber = self.comscoreMetadata.episodeSeasonNumber {
                builder?.setEpisodeSeasonNumber(episodeSeasonNumber)
            }
            if let episodeNumber = self.comscoreMetadata.episodeNumber {
                builder?.setEpisodeNumber(episodeNumber)
            }
            builder?.setGenreName(self.comscoreMetadata.genreName)
            if let genreId = self.comscoreMetadata.genreId {
                builder?.setGenreId(genreId)
            }
            if let carriesTvAdvertisementLoad = self.comscoreMetadata.carryTvAdvertisementLoad {
                builder?.carryTvAdvertisementLoad(carriesTvAdvertisementLoad)
            }
            if let classifyAsCompleteEpisode = self.comscoreMetadata.classifyAsCompleteEpisode {
                builder?.classify(asCompleteEpisode: classifyAsCompleteEpisode)
            }
            if let dateOfProduction = self.comscoreMetadata.productionDate {
                builder?.setDateOfProductionYear(dateOfProduction.year, month: dateOfProduction.month, day: dateOfProduction.day)
            }
            if let timeOfProduction = self.comscoreMetadata.productionTime {
                builder?.setTimeOfProductionHours(timeOfProduction.hours, minutes: timeOfProduction.minutes)
            }
            if let dateOfTvAiring = self.comscoreMetadata.tvAirDate {
                builder?.setDateOfTvAiringYear(dateOfTvAiring.year, month: dateOfTvAiring.month, day: dateOfTvAiring.day)
            }
            if let timeOfTvAiring = self.comscoreMetadata.tvAirTime {
                builder?.setTimeOfTvAiringHours(timeOfTvAiring.hours, minutes: timeOfTvAiring.minutes)
            }
            if let dateOfDigitalAiring = self.comscoreMetadata.digitalAirDate {
                builder?.setDateOfDigitalAiringYear(dateOfDigitalAiring.year, month: dateOfDigitalAiring.month, day: dateOfDigitalAiring.day)
            }
            if let timeOfDigitalAiring = self.comscoreMetadata.digitalAirTime {
                builder?.setTimeOfDigitalAiringHours(timeOfDigitalAiring.hours, minutes: timeOfDigitalAiring.minutes)
            }
            if let feedType = self.comscoreMetadata.feedType {
                builder?.setFeedType(feedType)
            }
            builder?.classify(asAudioStream: self.comscoreMetadata.classifyAsAudioStream)
            if let deliveryMode = self.comscoreMetadata.deliveryMode {
                builder?.setDeliveryMode(deliveryMode)
            }
            if let deliverySubscriptionType = self.comscoreMetadata.deliverySubscriptionType {
                builder?.setDeliverySubscriptionType(deliverySubscriptionType)
            }
            if let deliveryComposition = self.comscoreMetadata.deliveryComposition {
                builder?.setDeliveryComposition(deliveryComposition)
            }
            if let deliveryAdvertisementCapability = self.comscoreMetadata.deliveryAdvertisementCapability {
                builder?.setDeliveryAdvertisementCapability(deliveryAdvertisementCapability)
            }
            if let mediaFormat = self.comscoreMetadata.mediaFormat {
                builder?.setMediaFormat(mediaFormat)
            }
            if let distributionModel = self.comscoreMetadata.distributionModel {
                builder?.setDistributionModel(distributionModel)
            }
            if let playlistTitle = self.comscoreMetadata.playlistTitle {
                builder?.setPlaylistTitle(playlistTitle)
            }
            if let totalSegments = self.comscoreMetadata.totalSegments {
                builder?.setTotalSegments(totalSegments)
            }
            if let clipUrl = self.comscoreMetadata.clipUrl {
                builder?.setClipUrl(clipUrl)
            }
            if let videoDimension = self.comscoreMetadata.videoDimension {
                builder?.setVideoDimensionWidth(videoDimension.width, height: videoDimension.height)
            }
            builder?.setCustomLabels(self.comscoreMetadata.customLabels)
        }
        self.currentContentMetadata = contentMetadata
    }
    
    // MARK: - State transitions
    private func transitionToAdvertisement() {
        self.accessQueue.sync {
            if configuration.debug { print("[THEOplayerConnectorComscore] DEBUG: trying to transition to ADVERTISEMENT while in ", comscoreState.rawValue) }
            switch comscoreState {
            case .paused_ad, .initialized:
                if configuration.debug { print("[THEOplayerConnectorComscore] transitioned to ADVERTISEMENT while in ",comscoreState.rawValue) };
                comscoreState = .advertisement
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyPlay") }
                streamingAnalytics.notifyPlay()
                break
            case .video, .paused_video, .stopped:
                transitionToStopped();
                if configuration.debug { print("[THEOplayerConnectorComscore] transitioned to ADVERTISEMENT while in ",comscoreState.rawValue) }
                comscoreState = .advertisement
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyPlay") }
                streamingAnalytics.notifyPlay()
                break
            default:
                break
            }
        }
    }
    
    private func transitionToVideo() {
        self.accessQueue.sync {
            if configuration.debug { print("[THEOplayerConnectorComscore] trying to transition to VIDEO while in ", comscoreState.rawValue) }
            switch (comscoreState) {
            case .paused_video:
                if configuration.debug { print("[THEOplayerConnectorComscore] transitioned to VIDEO while in ", comscoreState.rawValue) }
                comscoreState = .video
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyPlay") }
                streamingAnalytics.notifyPlay()
                break
            case .advertisement, .paused_ad, .stopped:
                transitionToStopped()
                if configuration.debug { print("[THEOplayerConnectorComscore] transitioned to VIDEO while in ", comscoreState.rawValue) }
                comscoreState = .video
                setContentMetadata()
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyPlay") }
                streamingAnalytics.notifyPlay()
                break
            case .initialized:
                if configuration.debug { print("[THEOplayerConnectorComscore] transitioned to VIDEO while in ", comscoreState.rawValue) }
                comscoreState = .video
                setContentMetadata()
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyPlay") }
                streamingAnalytics.notifyPlay()
                break
            default:
                break
            }
        }
    }
    
    private func transitionToPaused() {
        self.accessQueue.sync {
            switch comscoreState {
            case .video:
                if configuration.debug { print("[THEOplayerConnectorComscore] Transition to PAUSED_VIDEO while in ",comscoreState.rawValue) }
                comscoreState = .paused_video
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyPause") }
                streamingAnalytics.notifyPause()
                break
            case .advertisement:
                if configuration.debug { print("[THEOplayerConnectorComscore] Transition to PAUSED_AD while in ",comscoreState.rawValue) }
                comscoreState = .paused_ad
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyPause") }
                streamingAnalytics.notifyPause()
                break
            default:
                if configuration.debug { print("[THEOplayerConnectorComscore] Ignoring transition to PAUSED while in ",comscoreState.rawValue) }
            }
        }
    }
    
    private func transitionToStopped() {
        self.accessQueue.sync {
            switch comscoreState {
            case .stopped, .initialized:
                if configuration.debug { print("[THEOplayerConnectorComscore] Ignoring transition to STOPPED while in STOPPED") }
                break
            default:
                if configuration.debug { print("[THEOplayerConnectorComscore] Transition to STOPPED while in ",comscoreState.rawValue) }
                comscoreState = .stopped
                if configuration.debug { print("[THEOplayerConnectorComscore] notifyEnd") }
                streamingAnalytics.notifyEnd()
            }
                
        }
    }
    
    // MARK: - Random
    func destroy() {
        if configuration.debug { print("[THEOplayerConnectorComscore] notifyEnd because app was killed") }
        transitionToStopped()
        if (self.listeners.count > 0) {
            self.removeEventListeners()
        }
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc func applicationWillResignActive() {
        //player.pause()
    }
    
    @objc func applicationWillTerminate() {
        streamingAnalytics.notifyEnd()
        if configuration.debug { print("[THEOplayerConnectorComscore] notifyEnd") }
    }
    
    
    // MARK: - THEO event handlers
    // Ads
    private func onAdbreakBegin(event: AdBreakBeginEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] AD_BREAK_BEGIN event") }
        currentAdOffset = Int((event.ad?.timeOffset)!);
        inAd = true;
        transitionToStopped()
    }
    
    private func onAdBegin(event: AdBeginEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] AD_BEGIN event") }
        if let ad = event.ad {
            currentAdDuration = 0
            if let duration = player.duration {
                if duration != .infinity && duration != .nan {
                    currentAdDuration = Int(duration * 1000)
                }
            }
            currentAdId = ad.id ?? "-1"
            if let adProcessor = configuration.adIdProcessor {
                currentAdId = adProcessor(ad)
            }
            setAdMetadata()
        }
    }
    
    private func onAdbreakEnd(event: AdBreakEndEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] AD_BREAK_END event") }
        inAd = false;
        transitionToStopped()
    }
    // Other
    private func onSourceChange(event: SourceChangeEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] SOURCECHANGE event") }
        comscoreState = .initialized
        currentContentMetadata = nil
        if configuration.debug { print("[THEOplayerConnectorComscore] createPlaybackSession") }
        streamingAnalytics.createPlaybackSession()
        streamingAnalytics.setMediaPlayerName("THEOplayer")
        streamingAnalytics.setMediaPlayerVersion(playerVersion)
    }
    
    private func onLoadedMetadata(event: LoadedMetaDataEvent) {
        if (comscoreMetadata.length == 0 && !inAd) {
            player.requestSeekable(completionHandler: { [weak self] seekableRanges, error in
                if let welf = self,
                   let foundRanges = seekableRanges?.sorted(by: { range1, range2 in range1.start < range2.start }),
                   foundRanges.count > 0,
                   let lastRange = foundRanges.last,
                   let firstRange = foundRanges.first {
                    let dvrWindowEnd = lastRange.end
                    let dvrWindowStart = firstRange.start
                    let dvrWindowLengthInSeconds = dvrWindowEnd - dvrWindowStart
                    if (dvrWindowLengthInSeconds > 0) {
                        if welf.configuration.debug { print("[THEOplayerConnectorComscore] set DVR window length of ",dvrWindowLengthInSeconds) }
                        welf.streamingAnalytics.setDVRWindowLength(Int(dvrWindowLengthInSeconds*1000))
                    }
                }
            })
        }
    }
    
    private func onPlaying(event: PlayingEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] PLAYING event") }
        if (isBuffering) {
            isBuffering = false
            if configuration.debug { print("[THEOplayerConnectorComscore] notifyBufferStop") }
            streamingAnalytics.notifyBufferStop()
        }
        
        if (isSeeking) {
            // player.seeking will already be false by now, so we maintain state in the adapter
            isSeeking = false
            if configuration.debug { print("[THEOplayerConnectorComscore] notifyPlay") }
            streamingAnalytics.notifyPlay()
        }
        
        if (inAd) {
            transitionToAdvertisement() // will set ad metadata and notifyPlay if not done already
        } else if (currentAdOffset < 0) {
            if configuration.debug { print("[THEOplayerConnectorComscore] ignoring PLAYING event after post-roll") }
            return // last played ad was a post-roll so there's no real content coming, return and report nothing
        } else {
            transitionToVideo() // will set content metadata and notifyPlay if not done already
        }
    }
    
    private func onPause(event: PauseEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] PAUSE event") }
        transitionToPaused()
    }
    
    private func onSeeking(event: SeekingEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] SEEKING event while in ", comscoreState.rawValue, " to currentTime ",event.currentTime) }
        if (event.currentTime == 0.0 && justRestarted) {
            return //ignore hiccup
        }
        
        if (comscoreState != .stopped && comscoreState != .initialized) {
            if configuration.debug { print("[THEOplayerConnectorComscore] notifySeekStart") }
            isSeeking = true
            streamingAnalytics.notifySeekStart()

        }
    }
    
    private func onSeeked(event: SeekedEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] SEEKED event") }
        if (comscoreState == .stopped && event.currentTime < 0.5) {
            if configuration.debug { print("[THEOplayerConnectorComscore] step out of seeked handler because we're restarting the same VOD") }
            currentAdOffset = 0
            return
        }
        if (justRestarted && event.currentTime == 0.0) {
            justRestarted = false //hiccup is over
        }
        let currentTime: Double = event.currentTime
        if (comscoreMetadata.length == 0) {
            player.requestSeekable(completionHandler: { [weak self] seekableRanges, error in
                if let welf = self,
                   let foundRanges = seekableRanges?.sorted(by: { range1, range2 in range1.start < range2.start }),
                   foundRanges.count > 0,
                   let lastRange = foundRanges.last {
                    let dvrWindowEnd = lastRange.end
                    let newDvrWindowOffsetInSeconds = dvrWindowEnd - currentTime
                    if welf.configuration.debug { print("[THEOplayerConnectorComscore] new dvr window offset ", newDvrWindowOffsetInSeconds) }
                    welf.streamingAnalytics.start(fromDvrWindowOffset: Int(newDvrWindowOffsetInSeconds*1000))
                }
            })
        } else {
            if configuration.debug { print("[THEOplayerConnectorComscore] startFromPosition ", currentTime) }
            streamingAnalytics.start(fromPosition: Int(currentTime*1000))
        }
    }
    
    private func onWaiting(event: WaitingEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] WAITING event at currentTime ", event.currentTime) }
        if (isBuffering) {
            return
        }
        if (justRestarted && event.currentTime == 0.0) {
            return // restart hiccup should be ignored
        }
        if ((comscoreState == .advertisement && inAd) || (comscoreState == .video && !inAd)) {
            isBuffering = true
            if configuration.debug { print("[THEOplayerConnectorComscore] notifyBufferStart") }
            streamingAnalytics.notifyBufferStart()
        }
    }
    
    private func onPlaybackRatechange(event: RateChangeEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] notifyChangePlaybackRate to ", event.playbackRate) }
        streamingAnalytics.notifyChangePlaybackRate(Float(event.playbackRate))
    }
    
    private func onError(event: ErrorEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] ERROR event") }
        transitionToStopped()
    }
    
    private func onEnded(event: EndedEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] ENDED event") }
        transitionToStopped()
        listeners["firstseekedafterended"] = player.addEventListener(type: PlayerEventTypes.SEEKED, listener: onFirstSeekedAfterEnded)
    }
    
    private func onDestroy(event: DestroyEvent) {
        if configuration.debug { print("[THEOplayerConnectorComscore] DESTROY event") }
        destroy()
    }
    
    private func onFirstSeekedAfterEnded(event: SeekedEvent) {
        if (event.currentTime < 0.5) {
            if configuration.debug { print("[THEOplayerConnectorComscore] SEEKED back to start after ENDED, initiate new session. BTW seeked to ",event.currentTime) }
            streamingAnalytics.createPlaybackSession();
            streamingAnalytics.setMediaPlayerName("THEOplayer")
            streamingAnalytics.setMediaPlayerVersion(playerVersion)
            player.removeEventListener(type: PlayerEventTypes.SEEKED, listener: listeners["firstseekedafterended"]!)
            justRestarted = true
        }
    }
}

