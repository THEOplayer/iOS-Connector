//
//  ViewController.swift
//  SideloadedTextTracksExample
//
//  Created by Wonne Joosen on 13/04/2024.
//

import UIKit
import THEOplayerSDK
import THEOplayerConnectorSideloadedSubtitle

class ViewController: UIViewController {
    
    
    @IBOutlet weak var playerViewContainer: UIView!
    var player: THEOplayer
    
    required init?(coder: NSCoder) {
//        self.player = THEOplayer(with: nil, configuration: THEOplayerConfiguration(chromeless: false, ads: AdsConfiguration(
//            showCountdown: true,
//            preload: AdPreloadType.MIDROLL_AND_POSTROLL,
//            googleIma: GoogleIMAAdsConfiguration(useNativeIma: false)
//        )))
        let playerConfiguration = THEOplayerConfigurationBuilder()
//        playerConfiguration.license = "<your license>"
        self.player = THEOplayer(with: nil, configuration: playerConfiguration.build())
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
    
    
    @IBAction func srtButtonClicked(_ sender: UIButton) {
        print("[SideloadedTextTracksExample] Setting source with SRT subtitles")
        player.setSourceWithSubtitles(source: SourceDescription(
            source: TypedSource(src: "https://cdn.theoplayer.com/video/elephants-dream/playlist-no-subtitles.m3u8", type: "application/x-mpegurl"),
            textTracks: [SSTextTrackDescription(src: "https://cdn.theoplayer.com/video/elephants-dream/captions.nl.srt", srclang: "en", isDefault: false, kind: .subtitles, label: "English", format: .SRT)]
        ))
    }
    
    @IBAction func vttButtonClicked(_ sender: UIButton) {
        print("[SideloadedTextTracksExample] Setting source with VTT subtitles")
        player.setSourceWithSubtitles(source: SourceDescription(
            source: TypedSource(src: "https://cdn.theoplayer.com/video/elephants-dream/playlist-no-subtitles.m3u8", type: "application/x-mpegurl"),
            textTracks: [SSTextTrackDescription(src: "https://cdn.theoplayer.com/video/elephants-dream/captions.en.vtt", srclang: "nl", isDefault: false, kind: .subtitles, label: "Nederlands", format: .WebVTT)]
        ))
    }
    
    @IBAction func togglePlayPause(_ sender: UIButton) {
        if (player.paused) {
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func toggleSubtitle(_ sender: UIButton) {
        var textTrack = player.textTracks.get(0)
        if textTrack.mode == .disabled {
            print("[SideloadedTextTracksExample] turning on subtitles")
            textTrack.mode = .showing
        } else {
            print("[SideloadedTextTracksExample] turning off subtitles")
            textTrack.mode = .disabled
        }
            
    }
    
    @IBAction func seekForward(_ sender: Any) {
        self.player.currentTime = self.player.currentTime + 10
    }
}

