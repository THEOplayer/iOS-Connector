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
    let conviva = ConvivaConnector(
        configuration: convivaConfig,
        player: THEOplayer(with: nil, configuration: nil)
    )!
    
    @IBOutlet weak var playerViewContainer: UIView!
    var player: THEOplayer { conviva.player }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playerView = PlayerView(player: player)
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.frame = playerViewContainer.bounds
        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerViewContainer.addSubview(playerView)
        
        conviva.report(viewerID: "User from CocoaPod example")
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
            )
        )
        report(assetName: "Big buck bunny")
    }
    
    @IBAction func starWarsButtonClicked(_ sender: UIButton) {
        player.source = SourceDescription(
            source: TypedSource(
                src: starwarsURL.absoluteString,
                type: "application/x-mpegurl"
            )
        )
        report(assetName: "Star wars episode VII the force awakens official comic-con 2015 reel (2015)")
    }
        
    func report(assetName: String) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            self.conviva.report(assetName: assetName)
        }
    }
}

let bigBuckBunnyURL = "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"
let starwarsURL = URL(string: "https://cdn.theoplayer.com/video/star_wars_episode_vii-the_force_awakens_official_comic-con_2015_reel_(2015)/index-daterange.m3u8")!
