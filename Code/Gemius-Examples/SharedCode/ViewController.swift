//
//  ViewController.swift
//  GemiusReporter
//
//  Created by Joosen, Wonne on 07/07/2025.
//

import UIKit
import THEOplayerSDK
import THEOplayerConnectorGemius
//import GemiusSDK

#if canImport(THEOplayerGoogleIMAIntegration)
import THEOplayerGoogleIMAIntegration
#endif

class ViewController: UIViewController {
    
    
    var gemius: GemiusConnector
    @IBOutlet weak var playerViewContainer: UIView!
    var player: THEOplayer
    
    required init?(coder: NSCoder) {
//        self.player = THEOplayer(with: nil, configuration: THEOplayerConfiguration(chromeless: false, ads: AdsConfiguration(
//            showCountdown: true,
//            preload: AdPreloadType.MIDROLL_AND_POSTROLL,
//            googleIma: GoogleIMAAdsConfiguration(useNativeIma: false)
//        )))
        self.player = THEOplayer(with: nil, configuration: THEOplayerConfigurationBuilder().build())
        #if canImport(THEOplayerGoogleIMAIntegration)
        let imaIntegration = GoogleIMAIntegrationFactory.createIntegration(on: player)
        player.addIntegration(imaIntegration)
        #endif
        self.gemius = GemiusConnector(
            configuration: GemiusConfiguration(implementationId: "test123", debug: true),
            player: player
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
        
        gemius.update()
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

        gemius.update()
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



