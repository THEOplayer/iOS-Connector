//
//  ViewController.swift
//  SideloadedTextTracksExample
//
//  Created by Wonne Joosen on 13/04/2024.
//

import UIKit
import THEOplayerSDK
import THEOplayerConnectorUplynk

class ViewController: UIViewController {
    private var player: THEOplayer!
    private var uplynkConnector: UplynkConnector!
    
    private var eventHandler: [EventListener] = []
    @IBOutlet weak var playerViewContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let configBuilder = THEOplayerConfigurationBuilder()
        configBuilder.license = "your licence"
        player = THEOplayer(with: nil, configuration: configBuilder.build())
        uplynkConnector = UplynkConnector(player: player)

        let playerView = PlayerView(player: player)
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.frame = playerViewContainer.bounds
        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.ADD_AD_BREAK) { [weak self] in
                print("--------------------------------------->")
                print("--> Add Ad Break Event occured: \($0)")
                print("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
                print("--> scheduled ad breaks are \(String(describing: self?.player.ads.scheduledAdBreaks))")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.REMOVE_AD_BREAK) { [weak self] in
                print("--------------------------------------->")
                print("--> Remove Ad Break Event occured: \($0)")
                print("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
                print("--> scheduled ad breaks are \(String(describing: self?.player.ads.scheduledAdBreaks))")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_BEGIN) { [weak self] in
                print("--------------------------------------->")
                print("--> Ad break begin Event occured: \($0)")
                print("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
                print("--> current ads \(String(describing: self?.player.ads.currentAds))")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_END) { [weak self] in
                print("--------------------------------------->")
                print("--> Ad break end Event occured: \($0)")
                print("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
                print("--> current ads \(String(describing: self?.player.ads.currentAds))")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_CHANGE) { [weak self] in
                print("--------------------------------------->")
                print("--> Ad break change event occured: \($0)")
                print("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.ADD_AD) {
                print("--------------------------------------->")
                print("--> Add Ad Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_BEGIN) {
                print("--------------------------------------->")
                print("--> Ad Begin Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_END) {
                print("--------------------------------------->")
                print("--> Ad End Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        playerViewContainer.addSubview(playerView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func adsButtonClicked(_ sender: UIButton) {
        player.source = SourceDescription(
            source: TypedSource(
                src: bigBuckBunnyURL,
                type: "application/x-mpegurl",
                ssai: uplynkAds
            )
        )
    }
    
    @IBAction func liveButtonClicked(_ sender: UIButton) {
        player.source = SourceDescription(
            source: TypedSource(
                src: bigBuckBunnyURL,
                type: "application/x-mpegurl",
                ssai: uplynkLive
            )
        )
    }
    
    @IBAction func drmButtonClicked(_ sender: UIButton) {
        player.source = SourceDescription(
            source: TypedSource(
                src: bigBuckBunnyURL,
                type: "application/x-mpegurl",
                ssai: uplynkDRM
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

    @IBAction func seekForward10(_ sender: Any) {
        self.player.setCurrentTime(self.player.currentTime + 10)
    }
    
    @IBAction func seekForward120(_ sender: Any) {
        self.player.setCurrentTime(self.player.currentTime + 120)
    }
    
    @IBAction func seekBack10(_ sender: Any) {
        self.player.setCurrentTime(self.player.currentTime - 10)
    }
    
    @IBAction func seekBack120(_ sender: Any) {
        self.player.setCurrentTime(self.player.currentTime - 120)
    }
    
    @IBAction func skipAd(_ sender: Any) {
        self.player.ads.skip()
    }
}

private extension ViewController {
    var bigBuckBunnyURL: String { "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8" }
    var uplynkAds: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["41afc04d34ad4cbd855db52402ef210e",
                                           "c6b61470c27d44c4842346980ec2c7bd",
                                           "588f9d967643409580aa5dbe136697a1",
                                           "b1927a5d5bd9404c85fde75c307c63ad",
                                           "7e9932d922e2459bac1599938f12b272",
                                           "a4c40e2a8d5b46338b09d7f863049675",
                                           "bcf7d78c4ff94c969b2668a6edc64278"],
                                externalIDs: [],
                                assetType: .asset,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [
                                    "ad": "adtest",
                                    "ad.lib": "15_sec_spots"
                                ],
                                uplynkPingConfiguration: .init(adImpressions: true,
                                                               freeWheelVideoViews: true,
                                                               linearAdData: false))
    }
    
    var uplynkLive: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["3c367669a83b4cdab20cceefac253684"],
                                externalIDs: [],
                                assetType: .channel,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [
                                    "ad": "cleardashnew",
                                ],
                                contentProtected: true,
                                uplynkPingConfiguration: .init(adImpressions: false,
                                                               freeWheelVideoViews: false,
                                                               linearAdData: true))
    }
    
    var uplynkDRM: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["e973a509e67241e3aa368730130a104d",
                                           "e70a708265b94a3fa6716666994d877d"],
                                externalIDs: [],
                                assetType: .asset,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [:],
                                contentProtected: true)
    }
}
