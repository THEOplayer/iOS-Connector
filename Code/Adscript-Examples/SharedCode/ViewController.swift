//
//  ViewController.swift
//  AdscriptReporter
//
//  Created by Joosen, Wonne on 14/06/2025.
//

import UIKit
import THEOplayerSDK
import THEOplayerConnectorAdscript
import AdScriptNoTrackingApiClient

#if canImport(THEOplayerGoogleIMAIntegration)
import THEOplayerGoogleIMAIntegration
#endif

class ViewController: UIViewController {
    
    
    var adscript: AdscriptConnector
    @IBOutlet weak var playerViewContainer: UIView!
    var player: THEOplayer
    
    required init?(coder: NSCoder) {
//        self.player = THEOplayer(with: nil, configuration: THEOplayerConfiguration(chromeless: false, ads: AdsConfiguration(
//            showCountdown: true,
//            preload: AdPreloadType.MIDROLL_AND_POSTROLL,
//            googleIma: GoogleIMAAdsConfiguration(useNativeIma: false)
//        )))
        self.player = THEOplayer(with: nil, configuration: THEOplayerConfigurationBuilder().build())
        let adscriptContentMetadata = AdScriptDataObject()
        #if canImport(THEOplayerGoogleIMAIntegration)
        let imaIntegration = GoogleIMAIntegrationFactory.createIntegration(on: player)
        player.addIntegration(imaIntegration)
        #endif
        self.adscript = AdscriptConnector(
            configuration: AdscriptConfiguration(implementationId: "test123", debug: true),
            player: player,
            metadata: adscriptContentMetadata
        )
        super.init(coder: coder)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let playerView = PlayerView(player: player)
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.frame = playerViewContainer.bounds
        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerViewContainer.addSubview(playerView)
        
    }
    
    
    @IBAction func bbbButtonClicked(_ sender: UIButton) {
        player.source = SourceDescription(
            source: TypedSource(
                src: bigBuckBunnyURL,
                type: "application/x-mpegurl"
            ),
            metadata: MetadataDescription(
                metadataKeys: nil,
                title: "Big buck bunny"
            )
        )
        var adscriptContentMetadata = AdScriptDataObject()
            .set(key: .length, value: 596)
            .set(key: .assetId, value: "0123ABC")
            .set(key: .channelId, value: "Dolby Test Asset")
            .set(key: .program, value: "Big Buck Bunny")
            .set(key: .livestream, value: "0")
            .set(key: .type, value: .content)
        
        adscript.update(metadata: adscriptContentMetadata)
    }
    
    @IBAction func starWarsButtonClicked(_ sender: UIButton) {
        player.source = SourceDescription(
            source: TypedSource(
                src: starwarsURL.absoluteString,
                type: "application/x-mpegurl"
            ),
            ads: [GoogleImaAdDescription(src: "https://cdn.theoplayer.com/demos/ads/vmap/single-pre-mid-post-no-skip.xml")],
            metadata: MetadataDescription(
                metadataKeys: nil,
                title: "Star wars episode VII the force awakens official comic-con 2015 reel (2015)"
            )
        )

        var adscriptContentMetadata = AdScriptDataObject()
            .set(key: .length, value: 211)
            .set(key: .assetId, value: "4567DEF")
            .set(key: .channelId, value: "Dolby Test Asset 2")
            .set(key: .program, value: "Star Wars: Episode VII The Force Awakens")
            .set(key: .livestream, value: "0")
            .set(key: .attribute, value: "1")
            .set(key: .type, value: .content)
        adscript.update(metadata: adscriptContentMetadata)
    }
    
    @IBAction func togglePlayPause(_ sender: UIButton) {
        if (player.paused) {
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func seekForward(_ sender: Any) {
        self.player.currentTime = self.player.currentTime + 10
    }
    
}

let bigBuckBunnyURL = "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"
let starwarsURL = URL(string: "https://cdn.theoplayer.com/video/star_wars_episode_vii-the_force_awakens_official_comic-con_2015_reel_(2015)/index-daterange.m3u8")!



