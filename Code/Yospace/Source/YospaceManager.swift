//
//  YospaceManager.swift
//
//  Created by Raffi on 29/05/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK
import YOAdManagement

class YospaceManager {
    let player: THEOplayerSDK.THEOplayer
    let eventDispatcher: EventDispatcher = .init()
    var didSetSourceFromConnector: Bool = false
    private(set) var adIntegrationController: THEOplayerSDK.ServerSideAdIntegrationController?
    private var adIntegrationHandler: THEOplayerSDK.ServerSideAdIntegrationHandler?
    private var yospaceSession: YOSession?
    private var source: YospaceManagerSource?
    private var id3MetadataHandler: YospaceID3MetadataHandler?
    private var playerEventsHandler: THEOplayerEventsHandler?
    private var yospaceNotificationsHandler: YospaceNotificationsHandler?
    private(set) var isSettingSource: Bool = false

    private typealias YospaceManagerSource = (THEOplayerSDK.SourceDescription, THEOplayerSDK.TypedSource)

    init(player: THEOplayerSDK.THEOplayer) {
		self.player = player

        self.player.ads.registerServerSideIntegration(integrationId: "yospace") { controller in
            self.adIntegrationController = controller
            let handler: THEOplayerSDK.ServerSideAdIntegrationHandler = YospaceHandler(player: player, manager: self)
            self.adIntegrationHandler = handler
            return handler
        }
	}

    func createYospaceSource(sourceDescription: THEOplayerSDK.SourceDescription, sessionProperties: YOSessionProperties?) -> Bool {
        // copy the passed SourceDescription; we don't want to modify the original
        let source: THEOplayerSDK.SourceDescription = sourceDescription.createCopy()
        let isYospaceSSAI: (TypedSource) -> Bool = { $0.ssai as? YospaceServerSideAdInsertionConfiguration != nil }

        if let typedSource: THEOplayerSDK.TypedSource = source.sources.first(where: isYospaceSSAI),
           let yospaceConfig: YospaceServerSideAdInsertionConfiguration = typedSource.ssai as? YospaceServerSideAdInsertionConfiguration {
            self.source = (source, typedSource)
            let src: String = typedSource.src.absoluteString
            switch yospaceConfig.streamType {
            case .live:
                YOSessionLive.create(src, properties: sessionProperties, completionHandler: self.onSessionCreate)
            case .livepause:
                YOSessionDVRLive.create(src, properties: sessionProperties, completionHandler: self.onSessionCreate)
            case .vod:
                YOSessionVOD.create(src, properties: sessionProperties, completionHandler: self.onSessionCreate)
            }
            return true
        } else {
            if self.didSetSourceFromConnector {
                let message: String = "Yospace: Could not find a TypedSource with a YospaceServerSideAdInsertionConfiguration."
                let error = YospaceError.error(msg: message)
                self.adIntegrationController?.fatalError(error: error, code: .AD_ERROR)
                return true
            } else {
                return false
            }
        }
    }

    func reset() {
        self.yospaceSession?.shutdown()
        self.yospaceSession = nil
        self.source = nil
        self.id3MetadataHandler = nil
        self.playerEventsHandler = nil
        self.yospaceNotificationsHandler = nil
        self.didSetSourceFromConnector = false
    }

    func destroy() {
        self.reset()
        self.adIntegrationHandler = nil
        self.adIntegrationController = nil
        self.eventDispatcher.clear()
    }

    private func onSessionCreate(session: YOSession) {
        let state: YOSessionState = session.sessionState
        if state == .initialised || state == .noAnalytics {
            self.setupManager(session: session)
        } else if state == .failed {
            let message: String = YOSession.YOSessionResultCode(rawValue: session.resultCode)?.message() ?? "Yospace: Session could not be initialised"
            let error = YospaceError.error(msg: message)
            self.adIntegrationController?.fatalError(error: error, code: .AD_ERROR)
        }
    }

    private func setupManager(session: YOSession) {
        if let playbackUrlStr: String = session.playbackUrl,
           let playbackUrl: URL = .init(string: playbackUrlStr) {
            self.yospaceSession = session
            (self.adIntegrationHandler as? YospaceHandler)?.session = session
            self.id3MetadataHandler = YospaceID3MetadataHandler(player: self.player, session: session)
            self.playerEventsHandler = THEOplayerEventsHandler(player: self.player, session: session)
            if let controller: THEOplayerSDK.ServerSideAdIntegrationController = self.adIntegrationController {
                self.yospaceNotificationsHandler = YospaceNotificationsHandler(session: session, adIntegrationController: controller, player: self.player)
            }
            if let source: YospaceManagerSource = self.source {
                let typedSource: THEOplayerSDK.TypedSource = source.1
                typedSource.src = playbackUrl
                let sourceDescription: THEOplayerSDK.SourceDescription = source.0
                self.isSettingSource = true
                self.player.source = sourceDescription
                self.isSettingSource = false
            }
            self.yospaceSession?.setPlaybackPolicyHandler(DefaultPlaybackPolicy(playbackMode: session.playbackMode))
            let event: SessionAvailableEvent = .init(date: Date())
            self.eventDispatcher.dispatchEvent(event: event)
        } else {
            let message: String = "Yospace: Could not resolve the playbackUrl of the YOSession."
            let error = YospaceError.error(msg: message)
            self.adIntegrationController?.fatalError(error: error, code: .AD_ERROR)
        }
    }

    deinit {
        self.destroy()
    }
}

class YospaceHandler: THEOplayerSDK.ServerSideAdIntegrationHandler {
    weak var player: THEOplayerSDK.THEOplayer?
    weak var manager: YospaceManager?
    var session: YOSession?

    init(player: THEOplayerSDK.THEOplayer, manager: YospaceManager) {
        self.player = player
        self.manager = manager
    }

    func setSource(source: SourceDescription) -> Bool {
        guard let manager: YospaceManager = self.manager else { return false }
        if manager.didSetSourceFromConnector {
            return false
        }
        return manager.createYospaceSource(sourceDescription: source, sessionProperties: nil)
    }

    func skipAd(ad: Ad) -> Bool {
        let isHandling: Bool = true
        guard let becomesSkippableIn: Double = self.session?.canSkip(),
              becomesSkippableIn > -1 else { return isHandling }
        if let currentAdvert: YOAdvert = self.session?.currentAdvert(),
           becomesSkippableIn == 0 {
            // is skippable now
            self.player?.currentTime = currentAdvert.start + currentAdvert.duration
            self.manager?.adIntegrationController?.skipAd(ad: ad)
        }
        return isHandling
    }

    func resetSource() -> Bool {
        if self.manager?.isSettingSource == false {
            self.manager?.reset()
            self.manager?.adIntegrationController?.removeAllAds()
        }
        return true
    }

    func destroy() {
        self.manager?.destroy()
    }
}
