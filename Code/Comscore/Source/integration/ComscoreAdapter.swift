//
//  theoComscoreAdapter.swift
//  theoplayer-comscore-ios-integration
//
//  Copyright © 2021 THEOPlayer. All rights reserved.
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
    private var currentAdCUSV: String = "-1"
    private var currentAdDuration: Int = 0
    private var currentAdOffset: Int = 0
    private var currentContentMetadata: SCORStreamingContentMetadata?
    private var inAd: Bool = false
    private var isBuffering: Bool = false
    private let player: THEOplayer
    private let playerVersion: String
    private let streamingAnalytics = SCORStreamingAnalytics()
    private var justRestarted: Bool = false
    
    private var currentVideoduration: Double = 0.0
    private var listeners: [String: EventListener] = [:]
    
    private let accessQueue = DispatchQueue(label: "ComScoreQueue", attributes: .concurrent)


    // MARK: - Public methods and constructor

    init(player: THEOplayer, playerVersion: String, configuration: ComScoreConfiguration, metadata: ComScoreMetadata?) {
        self.player = player
        self.playerVersion = playerVersion
        self.configuration = configuration
        self.comscoreMetadata = metadata ?? ComScoreMetadata(mediaType: .longFormOnDemand, length: 0) //TODO
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
        print("THEOLog: DEBUG: will kill")
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
        print("ComScore persistent label set: [\(label):\(value)]")
    }

    public func setPersistentLabels(labels: [String: String]) {
        notifyHiddenEvents(publisherId: self.configuration.publisherId, labels: labels)
        print("ComScore persistent labels set: [\(labels.map { "\($0.key):\($0.value)"})]")
    }
    
    private func attachEventListeners() {
        // Listen to event and store references in dictionary
        listeners["adbreakBegin"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_BEGIN, listener: onAdbreakBegin)
        listeners["adbreakEnd"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_END, listener: onAdbreakEnd)
        listeners["adBegin"] = player.ads.addEventListener(type: AdsEventTypes.AD_BEGIN, listener: onAdBegin)
        listeners["destroy"] = player.addEventListener(type: PlayerEventTypes.DESTROY, listener: onDestroy)
        listeners["ended"] = player.addEventListener(type: PlayerEventTypes.ENDED, listener: onEnded)
        print("THEOLog: DEBUG: added the ended listener")
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
        player.removeEventListener(type: AdsEventTypes.AD_BREAK_BEGIN, listener: listeners["adbreakBegin"]!)
        player.removeEventListener(type: AdsEventTypes.AD_BREAK_END, listener: listeners["adbreakEnd"]!)
        player.removeEventListener(type: AdsEventTypes.AD_BEGIN, listener: listeners["adBegin"]!)
        player.removeEventListener(type: PlayerEventTypes.DESTROY, listener: listeners["destroy"]!)
        player.removeEventListener(type: PlayerEventTypes.ENDED, listener: listeners["ended"]!)
        player.removeEventListener(type: PlayerEventTypes.ERROR, listener: listeners["error"]!)
        player.removeEventListener(type: PlayerEventTypes.LOADED_META_DATA, listener: listeners["loadedmetadata"]!)
        player.removeEventListener(type: PlayerEventTypes.PAUSE, listener: listeners["pause"]!)
        player.removeEventListener(type: PlayerEventTypes.RATE_CHANGE, listener: listeners["playbackRateChanged"]!)
        player.removeEventListener(type: PlayerEventTypes.PLAYING, listener: listeners["playing"]!)
        player.removeEventListener(type: PlayerEventTypes.SEEKED, listener: listeners["seeked"]!)
        player.removeEventListener(type: PlayerEventTypes.SEEKING, listener: listeners["seeking"]!)
        player.removeEventListener(type: PlayerEventTypes.SOURCE_CHANGE, listener: listeners["sourceChange"]!)
        player.removeEventListener(type: PlayerEventTypes.WAITING, listener: listeners["waiting"]!)
        
        listeners.removeAll()
    }
    
    // MARK: - Building and setting metadata
    private func setAdMetadata() {
        print("THEOLog: DEBUG: setting ad metadata with ad duration ", currentAdDuration, " and ad offset ", currentAdOffset)
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
            builder?.setUniqueId(self.currentAdCUSV)
            builder?.setLength(self.currentAdDuration)
            builder?.setRelatedContentMetadata(self.currentContentMetadata)
        }
        streamingAnalytics.setMetadata(advertisementMetadata)
    }
    
    private func setContentMetadata() {
        print("THEOLog: DEBUG: setting content metadata with duration ", comscoreMetadata.length)
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
    
    private func setCUSVId(ad: GoogleImaAd) {
        if (ad.adSystem == "GDFP" ) {
            currentAdCUSV = ad.creativeId!
        } else {
            currentAdCUSV = "-1"
            let uids = ad.universalAdIds
            let pattern = #"([a-z]{6}\w{7}[a-z])"#
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            for uid in uids {
                let uidvalue = uid.adIdValue
                if let match = regex?.firstMatch(in: uidvalue, options: [], range: NSRange(location: 0, length: uidvalue.utf16.count)) {
                    for i in 1..<match.numberOfRanges {
                        if let statusCodeRange = Range(match.range(at: i), in: uidvalue) {
                            print("CUSV found", uidvalue[statusCodeRange])
                            currentAdCUSV = String(uidvalue[statusCodeRange])
                            return
                        }
                    }
                    currentAdCUSV = "-2"
                }
            }
        }
    }
    
    // MARK: - State transitions
    private func transitionToAdvertisement() {
        self.accessQueue.sync {
            print("DEBUG: trying to transition to ADVERTISEMENT while in ", comscoreState.rawValue)
            switch comscoreState {
            case .paused_ad, .initialized:
                print("THEOLog: DEBUG: transitioned to ADVERTISEMENT while in ",comscoreState.rawValue);
                comscoreState = .advertisement
                print("THEOLog: DEBUG: notifyPlay")
                streamingAnalytics.notifyPlay()
                break
            case .video, .paused_video, .stopped:
                transitionToStopped();
                print("THEOLog: DEBUG: transitioned to ADVERTISEMENT while in ",comscoreState.rawValue)
                comscoreState = .advertisement
                print("THEOLog: DEBUG: notifyPlay")
                streamingAnalytics.notifyPlay()
                break
            default:
                break
            }
        }
    }
    
    private func transitionToVideo() {
        self.accessQueue.sync {
            print("THEOLog: DEBUG: trying to transition to VIDEO while in ", comscoreState.rawValue)
            switch (comscoreState) {
            case .paused_video:
                print("THEOLog: DEBUG: transitioned to VIDEO while in ", comscoreState.rawValue)
                comscoreState = .video
                print("THEOLog: DEBUG: notifyPlay")
                streamingAnalytics.notifyPlay()
                break
            case .advertisement, .paused_ad, .stopped:
                transitionToStopped()
                print("THEOLog: DEBUG: transitioned to VIDEO while in ", comscoreState.rawValue)
                comscoreState = .video
                setContentMetadata()
                print("THEOLog: DEBUG: notifyPlay")
                streamingAnalytics.notifyPlay()
                break
            case .initialized:
                print("THEOLog: DEBUG: transitioned to VIDEO while in ", comscoreState.rawValue)
                comscoreState = .video
                setContentMetadata()
                print("THEOLog: DEBUG: notifyPlay")
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
                print("THEOLog: DEBUG: Transition to PAUSED_VIDEO while in ",comscoreState.rawValue)
                comscoreState = .paused_video
                print("THEOLog: DEBUG: notifyPause")
                streamingAnalytics.notifyPause()
                break
            case .advertisement:
                print("THEOLog: DEBUG: Transition to PAUSED_AD while in ",comscoreState.rawValue)
                comscoreState = .paused_ad
                print("THEOLog: DEBUG: notifyPause")
                streamingAnalytics.notifyPause()
                break
            default:
                print("THEOLog: DEBUG: Ignoring transition to PAUSED while in ",comscoreState.rawValue)
            }
        }
    }
    
    private func transitionToStopped() {
        self.accessQueue.sync {
            switch comscoreState {
            case .stopped, .initialized:
                print("THEOLog: DEBUG: Ignoring transition to STOPPED while in STOPPED")
                break
            default:
                print("THEOLog: DEBUG: Transition to STOPPED while in ",comscoreState.rawValue)
                comscoreState = .stopped
                print("THEOLog: DEBUG: notifyEnd")
                streamingAnalytics.notifyEnd()
            }
                
        }
    }
    
    // MARK: - Random
    func destroy() {
        print("notifyEnd because app was killed")
        transitionToStopped()
        self.removeEventListeners()
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
        player.pause()
    }
    
    @objc func applicationWillTerminate() {
        streamingAnalytics.notifyEnd()
        print("THEOLog: DEBUG: notifyEnd")
    }
    
    
    // MARK: - THEO event handlers
    // Ads
    private func onAdbreakBegin(event: AdBreakBeginEvent) {
        print("THEOLog: DEBUG: AD_BREAK_BEGIN event")
        currentAdOffset = Int((event.ad?.timeOffset)!);
        inAd = true;
        transitionToStopped()
    }
    
    private func onAdBegin(event: AdBeginEvent) {
        print("THEOLog: DEBUG: AD_BEGIN event")
        let ad = event.ad as! GoogleImaAd
        currentAdDuration = Int(player.duration! * 1000)
        setCUSVId(ad: ad)
        setAdMetadata()
    }
    
    private func onAdbreakEnd(event: AdBreakEndEvent) {
        print("THEOLog: DEBUG: AD_BREAK_END event")
        inAd = false;
        transitionToStopped()
    }
    // Other
    private func onSourceChange(event: SourceChangeEvent) {
        print("THEOLog: DEBUG: SOURCECHANGE event")
        comscoreState = .initialized
        currentContentMetadata = nil
        print("THEOLog: DEBUG: createPlaybackSession")
        streamingAnalytics.createPlaybackSession()
        streamingAnalytics.setMediaPlayerName("THEOplayer")
        streamingAnalytics.setMediaPlayerVersion(playerVersion)
    }
    
    private func onLoadedMetadata(event: LoadedMetaDataEvent) {
        if (comscoreMetadata.length == 0 && !inAd) {
            player.requestSeekable(completionHandler: {seekableRanges, error in
                if ((seekableRanges?.count)! > 0) {
                    let dvrWindowEnd = seekableRanges!.last?.end
                    let dvrWindowLengthInSeconds = dvrWindowEnd! - seekableRanges!.first!.start
                    if (dvrWindowLengthInSeconds > 0) {
                        print("THEOLog: DEBUG: set DVR window length of ",dvrWindowLengthInSeconds)
                        self.streamingAnalytics.setDVRWindowLength(Int(dvrWindowLengthInSeconds*1000))
                    }
                }
            })
        }
    }
    
    private func onPlaying(event: PlayingEvent) {
        print("THEOLog: DEBUG:  PLAYING event handler")
        if (isBuffering) {
            isBuffering = false
            print("THEOLog: DEBUG: notifyBufferStop")
            streamingAnalytics.notifyBufferStop()
        }
        
        if (inAd) {
            transitionToAdvertisement() // will set ad metadata and notifyPlay if not done already
        } else if (currentAdOffset < 0) {
            print("THEOLog: DEBUG: ignoring PLAYING event after post-roll")
            return // last played ad was a post-roll so there's no real content coming, return and report nothing
        } else {
            transitionToVideo() // will set content metadata and notifyPlay if not done already
        }
    }
    
    private func onPause(event: PauseEvent) {
        print("THEOLog: DEBUG: PAUSE event")
        transitionToPaused()
    }
    
    private func onSeeking(event: SeekingEvent) {
        print("THEOLog: DEBUG: SEEKING event while in ", comscoreState.rawValue, " to currentTime ",event.currentTime)
        if (event.currentTime == 0.0 && justRestarted) {
            return //ignore hiccup
        }
        
        if (comscoreState != .stopped && comscoreState != .initialized) {
            print("THEOLog: DEBUG: notifySeekStart")
            streamingAnalytics.notifySeekStart()

        }
    }
    
    private func onSeeked(event: SeekedEvent) {
        print("THEOLog: DEBUG: SEEKED event")
        if (comscoreState == .stopped && event.currentTime < 0.5) {
            print("THEOLog: DEBUG: step out of seeked handler because we're restarting the same VOD")
            currentAdOffset = 0
            return
        }
        if (justRestarted && event.currentTime == 0.0) {
            justRestarted = false //hiccup is over
        }
        let currentTime: Double = event.currentTime
        if (comscoreMetadata.length == 0) {
            player.requestSeekable(completionHandler: { seekableRanges, error in
                let dvrWindowEnd = seekableRanges!.last?.end
                let newDvrWindowOffsetInSeconds = dvrWindowEnd! - currentTime
                print("THEOLog: DEBUG: new dvr window offset ", newDvrWindowOffsetInSeconds)
                self.streamingAnalytics.start(fromDvrWindowOffset: Int(newDvrWindowOffsetInSeconds*1000))
            })
        } else {
            print("THEOLog: DEBUG: startFromPosition ", currentTime)
            streamingAnalytics.start(fromPosition: Int(currentTime*1000))
        }
    }
    
    private func onWaiting(event: WaitingEvent) {
        print("THEOLog: DEBUG: WAITING event at currentTime ", event.currentTime)
        if (isBuffering) {
            return
        }
        if (justRestarted && event.currentTime == 0.0) {
            return // restart hiccup should be ignored
        }
        if ((comscoreState == .advertisement && inAd) || (comscoreState == .video && !inAd)) {
            isBuffering = true
            print("THEOLog: DEBUG: notifyBufferStart")
            streamingAnalytics.notifyBufferStart()
        }
    }
    
    private func onPlaybackRatechange(event: RateChangeEvent) {
        print("THEOLog: DEBUG: notifyChangePlaybackRate to ", event.playbackRate)
        streamingAnalytics.notifyChangePlaybackRate(Float(event.playbackRate))
    }
    
    private func onError(event: ErrorEvent) {
        print("THEOLog: DEBUG: ERROR event")
        transitionToStopped()
    }
    
    private func onEnded(event: EndedEvent) {
        print("THEOLog: DEBUG: ENDED event")
        transitionToStopped()
        listeners["firstseekedafterended"] = player.addEventListener(type: PlayerEventTypes.SEEKED, listener: onFirstSeekedAfterEnded)
    }
    
    private func onDestroy(event: DestroyEvent) {
        print("THEOLog: DEBUG: DESTROY event")
        destroy()
    }
    
    private func onFirstSeekedAfterEnded(event: SeekedEvent) {
        if (event.currentTime < 0.5) {
            print("THEOLog: DEBUG: SEEKED back to start after ENDED, initiate new session. BTW seeked to ",event.currentTime)
            streamingAnalytics.createPlaybackSession();
            streamingAnalytics.setMediaPlayerName("THEOplayer")
            streamingAnalytics.setMediaPlayerVersion(playerVersion)
            player.removeEventListener(type: PlayerEventTypes.SEEKED, listener: listeners["firstseekedafterended"]!)
            justRestarted = true
        }
    }
}

