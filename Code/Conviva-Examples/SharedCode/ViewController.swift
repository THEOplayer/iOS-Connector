//
//  ViewController.swift
//  THEOplayerConvivaConnector
//
//  Created by Damiaan on 09/29/2022.
//  Copyright (c) 2022 Damiaan. All rights reserved.
//

import UIKit
import THEOplayerSDK
import THEOplayerConnectorConviva

class ViewController: UIViewController {
    let player = THEOplayer(with: nil, configuration: nil)
    var conviva: ConvivaConnector?
    
    @IBOutlet weak var playerViewContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.conviva = ConvivaConnector(configuration: convivaConfig, player: self.player)
        let playerView = PlayerView(player: player)
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.frame = playerViewContainer.bounds
        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerViewContainer.addSubview(playerView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    }

    @IBAction func togglePlayPause(_ sender: UIButton) {
        if self.player.paused {
            self.player.play()
        } else {
            self.player.pause()
        }
    }

    @IBAction func seekForward(_ sender: Any) {
        self.player.setCurrentTime(self.player.currentTime + 10)
    }
}

let bigBuckBunnyURL = "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"
let starwarsURL = URL(string: "https://cdn.theoplayer.com/video/star_wars_episode_vii-the_force_awakens_official_comic-con_2015_reel_(2015)/index-daterange.m3u8")!
