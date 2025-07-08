import THEOplayerSDK
#if canImport(GemiusSDK)
import GemiusSDK
#endif

let LOG_PLAYER_EVENTS = false
let LOG_GEMIUS_EVENTS = false

public class GemiusAdapter {
    private let player: THEOplayer
    private let configuration: GemiusConfiguration
    private var gsmPlayer: GSMPlayer
    
    private var programId: String?
    private var programData: GemiusSDK.GSMProgramData?
    
    private var playEventListener: EventListener?
    private var playingEventListener: EventListener?
    private var errorEventListener: EventListener?
    private var sourceChangeEventListener: EventListener?
    private var endedEventListener: EventListener?
    private var durationChangeEventListener: EventListener?
    private var timeUpdateEventListener: EventListener?
    private var volumeChangeEventListener: EventListener?
    private var rateChangeEventListener: EventListener?
    private var presentationModeChangeEventListener: EventListener?
    
    private var adBreakBeginListener: EventListener?
    private var adBeginListener: EventListener?
    private var adFirstQuartileListener: EventListener?
    private var adMidpointListener: EventListener?
    private var adThirdQuartileListener: EventListener?
    private var adCompletedListener: EventListener?
    private var adBreakEndedListener: EventListener?
    

    public init(configuration: GemiusConfiguration, player: THEOplayer) {
        self.player = player
        self.configuration = configuration
        let playerData = GemiusSDK.GSMPlayerData()
        playerData.resolution = "\(player.frame.width)x\(player.frame.height)"
        if (player.muted) {
            playerData.volume = -1
        } else {
            playerData.volume = NSNumber(value: player.volume * 100)
        }
        self.gsmPlayer = GemiusSDK.GSMPlayer(id: configuration.playerId, withHost: configuration.hitCollectorHost, withGemiusID: configuration.gemiusId, with: playerData)
        
        addEventListeners()
    }
        
    public func update(programId: String, programData: GemiusSDK.GSMProgramData) {
        self.programId = programId
        self.programData = programData
    }
    
    
    private func addEventListeners() {
        self.playEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAY, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if (welf.configuration.debug && LOG_PLAYER_EVENTS) {
                print("[GemiusConnector] Player Event: \(event.type) : currentTime = \(event.currentTime)")
            }
        })
        self.playingEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener:  { [weak self] event in self?.handlePlaying(event: event) })
        self.errorEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.ERROR, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if let code = event.errorObject?.code, let cause = event.errorObject?.cause, welf.configuration.debug && LOG_PLAYER_EVENTS {
                print("[GemiusConnector] Player Event: \(event.type) : code = \(code) ; cause = \(cause)")
            }
        })
        self.sourceChangeEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.SOURCE_CHANGE, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if (welf.configuration.debug && LOG_PLAYER_EVENTS) {
                print("[GemiusConnector] Player Event: \(event.type) : source = \(event.source.debugDescription)")
            }
            if let programData = welf.programData, let programId = welf.programId {
                welf.gsmPlayer.newProgram(programId, with: programData)
            }
            
            if let playingEventListener: THEOplayerSDK.EventListener = welf.playingEventListener {
                welf.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener: playingEventListener)
            }
            welf.playingEventListener = welf.player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener:  { [weak self] event in self?.handlePlaying(event: event) })
        })
        self.endedEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.ENDED, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if (welf.configuration.debug && LOG_PLAYER_EVENTS) {
                print("[GemiusConnector] Player Event: \(event.type) : currentTime = \(event.currentTime)")
            }
        })
        self.durationChangeEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.DURATION_CHANGE, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if let duration = event.duration, welf.configuration.debug && LOG_PLAYER_EVENTS {
                print("[GemiusConnector] Player Event: \(event.type) : duration = \(duration)")
            }
        })
        self.timeUpdateEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.TIME_UPDATE, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if (welf.configuration.debug && LOG_PLAYER_EVENTS) {
                print("[GemiusConnector] Player Event: \(event.type) : currentTime = \(event.currentTime)")
            }
        })
        self.volumeChangeEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.VOLUME_CHANGE, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if (welf.configuration.debug && LOG_PLAYER_EVENTS) {
                print("[GemiusConnector] Player Event: \(event.type) : volume = \(event.volume)")
            }
        })
        self.rateChangeEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.RATE_CHANGE, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if (welf.configuration.debug && LOG_PLAYER_EVENTS) {
                print("[GemiusConnector] Player Event: \(event.type) : playbackRate = \(event.playbackRate)")
            }
        })
        self.presentationModeChangeEventListener = player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.PRESENTATION_MODE_CHANGE, listener: { [weak self] event in
            guard let welf: GemiusAdapter = self else { return }
            if (welf.configuration.debug && LOG_PLAYER_EVENTS) {
                print("[GemiusConnector] Player Event: \(event.type) : presentationMode = \(event.presentationMode._rawValue)")
            }
        })
        
    
        if (hasAdIntegration()) {
            self.adBreakBeginListener = player.ads.addEventListener(type: THEOplayerSDK.AdsEventTypes.AD_BREAK_BEGIN, listener: { [weak self] event in
                guard let welf: GemiusAdapter = self else { return }
                if let offset = event.ad?.timeOffset, welf.configuration.debug && LOG_PLAYER_EVENTS {
                    print("[GemiusConnector] Player Event: \(event.type) : offset = \(offset)")
                }
            })
            self.adBeginListener = player.ads.addEventListener(type: THEOplayerSDK.AdsEventTypes.AD_BEGIN, listener: { [weak self] event in
                guard let welf: GemiusAdapter = self else { return }
                if let id = event.ad?.id, welf.configuration.debug && LOG_PLAYER_EVENTS {
                    print("[GemiusConnector] Player Event: \(event.type) : id = \(id)")
                }
                guard let ad = event.ad else { return }
            })
            self.adFirstQuartileListener = player.ads.addEventListener(type: THEOplayerSDK.AdsEventTypes.AD_FIRST_QUARTILE, listener: { [weak self] event in
                guard let welf: GemiusAdapter = self else { return }
                if let id = event.ad?.id, welf.configuration.debug && LOG_PLAYER_EVENTS {
                    print("[GemiusConnector] Player Event: \(event.type) : id = \(id)")
                }
            })
            self.adMidpointListener = player.ads.addEventListener(type: THEOplayerSDK.AdsEventTypes.AD_MIDPOINT, listener: { [weak self] event in
                guard let welf: GemiusAdapter = self else { return }
                if let id = event.ad?.id, welf.configuration.debug && LOG_PLAYER_EVENTS {
                    print("[GemiusConnector] Player Event: \(event.type) : id = \(id)")
                }
            })
            self.adThirdQuartileListener = player.ads.addEventListener(type: THEOplayerSDK.AdsEventTypes.AD_THIRD_QUARTILE, listener: { [weak self] event in
                guard let welf: GemiusAdapter = self else { return }
                if let id = event.ad?.id, welf.configuration.debug {
                    print("[GemiusConnector] Player Event: \(event.type) : id = \(id)")
                }
            })
            self.adCompletedListener = player.ads.addEventListener(type: THEOplayerSDK.AdsEventTypes.AD_END, listener: { [weak self] event in
                guard let welf: GemiusAdapter = self else { return }
                if let id = event.ad?.id, welf.configuration.debug && LOG_PLAYER_EVENTS {
                    print("[GemiusConnector] Player Event: \(event.type) : id = \(id)")
                }
            })
            self.adBreakEndedListener = player.ads.addEventListener(type: THEOplayerSDK.AdsEventTypes.AD_BREAK_END, listener: { [weak self] event in
                guard let welf: GemiusAdapter = self else { return }
                if let offset = event.ad?.timeOffset, welf.configuration.debug && LOG_PLAYER_EVENTS {
                    print("[GemiusConnector] Player Event: \(event.type) : offset = \(offset)")
                }
                if (event.ad?.timeOffset == 0) {
                    welf.playingEventListener = welf.player.addEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener:  { [weak self] event in self?.handlePlaying(event: event) })
                }
            })
        }
    }

    private func removeEventListeners() {
        if let playEventListener: THEOplayerSDK.EventListener = self.playEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.TIME_UPDATE, listener: playEventListener)
        }
        if let playingEventListener: THEOplayerSDK.EventListener = self.playingEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener: playingEventListener)
        }
        if let errorEventListener: THEOplayerSDK.EventListener = self.errorEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.ERROR, listener: errorEventListener)
        }
        if let sourceChangeEventListener: THEOplayerSDK.EventListener = self.sourceChangeEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.SOURCE_CHANGE, listener: sourceChangeEventListener)
        }
        if let endedEventListener: THEOplayerSDK.EventListener = self.endedEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.ENDED, listener: endedEventListener)
        }
        if let durationChangeEventListener: THEOplayerSDK.EventListener = self.durationChangeEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.DURATION_CHANGE, listener: durationChangeEventListener)
        }
        if let timeUpdateEventListener: THEOplayerSDK.EventListener = self.timeUpdateEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.TIME_UPDATE, listener: timeUpdateEventListener)
        }
        if let volumeChangeEventListener: THEOplayerSDK.EventListener = self.volumeChangeEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.VOLUME_CHANGE, listener: volumeChangeEventListener)
        }
        if let rateChangeEventListener: THEOplayerSDK.EventListener = self.rateChangeEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.RATE_CHANGE, listener: rateChangeEventListener)
        }
        if let presentationModeChangeEventListener: THEOplayerSDK.EventListener = self.presentationModeChangeEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.PRESENTATION_MODE_CHANGE, listener: presentationModeChangeEventListener)
        }
        if let adBreakBeginListener: THEOplayerSDK.EventListener = self.adBreakBeginListener {
            self.player.removeEventListener(type: THEOplayerSDK.AdsEventTypes.AD_BREAK_BEGIN, listener: adBreakBeginListener)
        }
        if let adBeginListener: THEOplayerSDK.EventListener = self.adBeginListener {
            self.player.removeEventListener(type: THEOplayerSDK.AdsEventTypes.AD_BEGIN, listener: adBeginListener)
        }
        if let adFirstQuartileListener: THEOplayerSDK.EventListener = self.adFirstQuartileListener {
            self.player.removeEventListener(type: THEOplayerSDK.AdsEventTypes.AD_FIRST_QUARTILE, listener: adFirstQuartileListener)
        }
        if let adMidpointListener: THEOplayerSDK.EventListener = self.adMidpointListener {
            self.player.removeEventListener(type: THEOplayerSDK.AdsEventTypes.AD_MIDPOINT, listener: adMidpointListener)
        }
        if let adThirdQuartileListener: THEOplayerSDK.EventListener = self.adThirdQuartileListener {
            self.player.removeEventListener(type: THEOplayerSDK.AdsEventTypes.AD_THIRD_QUARTILE, listener: adThirdQuartileListener)
        }
        if let adCompletedListener: THEOplayerSDK.EventListener = self.adCompletedListener {
            self.player.removeEventListener(type: THEOplayerSDK.AdsEventTypes.AD_END, listener: adCompletedListener)
        }
        if let adBreakEndedListener: THEOplayerSDK.EventListener = self.adBreakEndedListener {
            self.player.removeEventListener(type: THEOplayerSDK.AdsEventTypes.AD_BREAK_END, listener: adBreakEndedListener)
        }
    }
    
    private func handlePlaying(event: PlayingEvent) {
        if (self.configuration.debug && LOG_PLAYER_EVENTS) {
            print("[GemiusConnector] Player Event: \(event.type) : currentTime = \(event.currentTime)")
        }
        if let playingEventListener: THEOplayerSDK.EventListener = self.playingEventListener {
            self.player.removeEventListener(type: THEOplayerSDK.PlayerEventTypes.PLAYING, listener: playingEventListener)
        }
    }
    
    private func hasAdIntegration() -> Bool {
        let hasAdIntegration = player.getAllIntegrations().contains { integration in
            switch integration.kind {
            case IntegrationKind.GOOGLE_DAI:
                return true
            case IntegrationKind.GOOGLE_IMA:
                return true
            default:
                print("[GemiusConnector] no supported ad integration was found")
                return false
            }
        }
        return hasAdIntegration
    }
}
