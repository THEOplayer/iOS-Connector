//
//  ViewController.swift
//  THEOplayerConvivaConnector
//
//  Created by Damiaan on 09/29/2022.
//  Copyright (c) 2022 Damiaan. All rights reserved.
//

import UIKit
import THEOplayerSDK
import THEOplayerConvivaConnector

class ViewController: UIViewController {
    let conviva = ConvivaConnector(
        configuration: convivaConfig,
        player: THEOplayer(
            with: nil,
            configuration: .init(
                ads: imaAdsConfig,
                verizonMedia: VerizonMediaConfiguration(defaultSkipOffset: 2, onSeekOverAd: .PLAY_LAST)
            )
        )
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
    
    @IBAction func imaButtonClicked(_ sender: UIButton) {
//        let typedSource = TypedSource(src: bigBuckBunnyURL, type: "application/x-mpegurl")
//        let imaTag = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostpodbumper&cmsid=496&vid=short_onecue&correlator="
//        player.source = SourceDescription(source : typedSource, ads: [GoogleImaAdDescription(src: imaTag)])
//        report(assetName: "IMA source with ads")
    }
    
    @IBAction func VerizonButtonClicked(_ sender: UIButton) {
//        player.source = verizonMediaWithAds
//        report(assetName: "VerizonMedia with ads")
    }
    
    func report(assetName: String) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            self.conviva.report(assetName: assetName)
        }
    }
}

let imaAdsConfig = AdsConfiguration(
    showCountdown: true,
    preload: .MIDROLL_AND_POSTROLL,
    googleImaConfiguration: .init(useNativeIma: false)
)

let bigBuckBunnyURL = "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"
let starwarsURL = URL(string: "https://cdn.theoplayer.com/video/star_wars_episode_vii-the_force_awakens_official_comic-con_2015_reel_(2015)/index-daterange.m3u8")!

//var verizonMediaSingleAsset_DRM : SourceDescription {
//    let verizonMediaTs = VerizonMediaSource(assetIds: ["e973a509e67241e3aa368730130a104d"], parameters: nil, assetType: .ASSET, contentProtected: true)
//    return SourceDescription(source: verizonMediaTs)
//}
//
//var verizonMediaWithAds: SourceDescription {
//    let verizonMediaTs = VerizonMediaSource(
//        assetIds: [
//            "41afc04d34ad4cbd855db52402ef210e",
//            "c6b61470c27d44c4842346980ec2c7bd",
//            "588f9d967643409580aa5dbe136697a1",
//            "b1927a5d5bd9404c85fde75c307c63ad",
//            "7e9932d922e2459bac1599938f12b272",
//            "a4c40e2a8d5b46338b09d7f863049675",
//            "bcf7d78c4ff94c969b2668a6edc64278"
//        ],
//        parameters: ["ad": "adtest", "ad.lib": "15_sec_spots"],
//        assetType: .ASSET,
//        contentProtected: nil,
//        ping: nil
//    )
//    return SourceDescription(source: verizonMediaTs)
//}
