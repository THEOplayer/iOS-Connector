//
//  ViewController.swift
//  ComscoreReporter
//
//  Created by Wonne Joosen on 10/03/2023.
//

import UIKit
import THEOplayerSDK
import THEOplayerConnectorComscore

class ViewController: UIViewController {
    
    let comscore = ComscoreConnector(
        configuration: comscoreConfig,
        player: THEOplayer(with: nil, configuration: nil),
        metadata: ComScoreMetadata(mediaType: .shortFormOnDemand, uniqueId: "0123ABC", length: 596, stationTitle: "THEO TV", programTitle: "Big Buck Bunny", episodeTitle: "Example Title", genreName: "animation", classifyAsAudioStream: false)
    )
    
    @IBOutlet weak var playerViewContainer: UIView!
    var player: THEOplayer { comscore.player }
    

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
        comscore.comscore.update(metadata: ComScoreMetadata(mediaType: .shortFormOnDemand, uniqueId: "0123ABC", length: 596, stationTitle: "THEO TV", programTitle: "Big Buck Bunny", episodeTitle: "Example Title", genreName: "animation", classifyAsAudioStream: false))
    }
    
    @IBAction func starWarsButtonClicked(_ sender: UIButton) {
        player.source = SourceDescription(
            source: TypedSource(
                src: starwarsURL.absoluteString,
                type: "application/x-mpegurl"
            ),
            metadata: MetadataDescription(
                metadataKeys: nil,
                title: "Star wars episode VII the force awakens official comic-con 2015 reel (2015)"
            )
        )
        comscore.comscore.update(metadata: ComScoreMetadata(mediaType: .shortFormOnDemand, uniqueId: "4567DEF", length: 211, stationTitle: "THEO TV", programTitle: "Star Wars", episodeTitle: "Episode VII The Force Awakens", genreName: "Science Fiction", classifyAsAudioStream: false))
    }
}

let bigBuckBunnyURL = "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"
let starwarsURL = URL(string: "https://cdn.theoplayer.com/video/star_wars_episode_vii-the_force_awakens_official_comic-con_2015_reel_(2015)/index-daterange.m3u8")!

