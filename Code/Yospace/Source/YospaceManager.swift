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
    private var adIntegrationController: THEOplayerSDK.ServerSideAdIntegrationController?
    private var yospaceSession: YOSession?
    private var source: YospaceManagerSource?
    private var id3MetadataHandler: YospaceID3MetadataHandler?
    private var playerEventsHandler: THEOplayerEventsHandler?
    private var yospaceNotificationsHandler: YospaceNotificationsHandler?

    private typealias YospaceManagerSource = (THEOplayerSDK.SourceDescription, THEOplayerSDK.TypedSource)

    init(player: THEOplayerSDK.THEOplayer) {
		self.player = player

        self.player.ads.registerServerSideIntegration(integrationId: "yospace") { controller in
            self.adIntegrationController = controller
            return Handler()
        }
	}

    func createYospaceSource(sourceDescription: THEOplayerSDK.SourceDescription, sessionProperties: YOSessionProperties?) {
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
        }
    }

    private func onSessionCreate(session: YOSession) {
        let state: YOSessionState = session.sessionState
        if let playbackUrlStr: String = session.playbackUrl,
           let playbackUrl: URL = .init(string: playbackUrlStr),
           state == .initialised || state == .noAnalytics {
            self.yospaceSession = session
            self.id3MetadataHandler = YospaceID3MetadataHandler(player: self.player, session: session)
            self.playerEventsHandler = THEOplayerEventsHandler(player: self.player, session: session)
            self.yospaceNotificationsHandler = YospaceNotificationsHandler(session: session)
            if let source: YospaceManagerSource = self.source {
                let typedSource: THEOplayerSDK.TypedSource = source.1
                typedSource.src = playbackUrl
                let sourceDescription: THEOplayerSDK.SourceDescription = source.0
                self.player.source = sourceDescription
            }
            self.yospaceSession?.setPlaybackPolicyHandler(DefaultPlaybackPolicy(playbackMode: session.playbackMode))
        }
    }

    private func reset() {
        self.yospaceSession?.shutdown()
        self.yospaceSession = nil
        self.source = nil
        self.id3MetadataHandler = nil
        self.playerEventsHandler = nil
        self.yospaceNotificationsHandler = nil
    }

    deinit {
        self.reset()
    }
}

class Handler: ServerSideAdIntegrationHandler {
    func setSource(source: SourceDescription) -> SourceDescription { .init(source: .init(src: .init(), type: .init())) }
    func skipAd(ad: Ad) {}
    func resetSource() {}
    func destroy() {}
}
