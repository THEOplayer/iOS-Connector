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
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var sourceSegmentedControl: UISegmentedControl!
    @IBOutlet weak var skipStrategySegmentedControl: UISegmentedControl!
    @IBOutlet weak var adsConfigurationStackView: UIStackView!
    @IBOutlet weak var skipOffsetValue: UILabel!
    @IBOutlet weak var seekSecondsTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        resetState()
        initialisePlayer()
    }
    
    func resetState() {
        skipOffsetValue.text = "\(Int(stepper.value))"
        skipStrategySegmentedControl.selectedSegmentIndex = 0
        adsConfigurationStackView.isHidden = sourceSegmentedControl.selectedSegmentIndex != 1
    }
    
    private var selectedSkipStrategy: SkippedAdStrategy {
        switch skipStrategySegmentedControl.selectedSegmentIndex {
        case 1:
            return .playAll
        case 2:
            return .playLast
        default:
            return .playNone
        }
    }
    
    private var selectedSkipOffsetValue: Int {
        Int(stepper.value)
    }
    
    func initialisePlayer() {
        playerViewContainer.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let configBuilder = THEOplayerConfigurationBuilder()
        configBuilder.license = "your licence"
        player = THEOplayer(with: nil, 
                            configuration: configBuilder.build())
        
        uplynkConnector = UplynkConnector(player: player,
                                          configuration: .init(defaultSkipOffset: selectedSkipOffsetValue,
                                                               skippedAdStrategy: selectedSkipStrategy))

        let playerView = PlayerView(player: player)
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.frame = playerViewContainer.bounds
        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerViewContainer.addSubview(playerView)
        
        addEventListeners()
        
        switch sourceSegmentedControl.selectedSegmentIndex {
        case 0:
            player.source = .live
        case 1:
            player.source = .ads
//            Task { @MainActor in
//                if let source = await SourceDescription.source(for: .source1) {
//                    player.source = source
//                }
//            }
        case 2:
            player.source = .multiDRM
        default:
            // No-op
            break
        }
    }
    
    func addEventListeners() {
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
                print("--> Ad break change Event occured: \($0)")
                print("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.UPDATE_AD_BREAK) { [weak self] in
                print("--------------------------------------->")
                print("--> Ad Break Update Event occured: \($0)")
                print("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
                print("--> current ads \(String(describing: self?.player.ads.currentAds))")
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
            player.ads.addEventListener(type: AdsEventTypes.UPDATE_AD) {
                print("--------------------------------------->")
                print("--> Ad Update Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_FIRST_QUARTILE) {
                print("--------------------------------------->")
                print("--> Ad First Quartile Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_MIDPOINT) {
                print("--------------------------------------->")
                print("--> Ad Mid Point Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_THIRD_QUARTILE) {
                print("--------------------------------------->")
                print("--> Ad Third Quartile Event occured: \($0)")
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
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_LOADED) {
                print("--------------------------------------->")
                print("--> Ad Loaded Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_IMPRESSION) {
                print("--------------------------------------->")
                print("--> Ad Impresssion Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_ERROR) {
                print("--------------------------------------->")
                print("--> Ad Error Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_SKIP) {
                print("--------------------------------------->")
                print("--> Ad Skip Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_TAPPED) {
                print("--------------------------------------->")
                print("--> Ad Tapped Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
        
        eventHandler.append(
            player.ads.addEventListener(type: AdsEventTypes.AD_CLICKED) {
                print("--------------------------------------->")
                print("--> Ad Clicked Event occured: \($0)")
                print("--------------------------------------->")
            }
        )
    }

    @IBAction func onChangeSource(_ sender: Any) {
        stop()
        resetState()
        initialisePlayer()
    }

    @IBAction func onChangeSkipOffset(_ sender: Any) {
        stop()
        skipOffsetValue.text = "\(Int(stepper.value))"
        initialisePlayer()
    }
    
    @IBAction func onChangeSkipStrategySelection(_ sender: Any) {
        stop()
        initialisePlayer()
    }

    @IBAction func togglePlayPause(_ sender: UIButton) {
        if self.player.paused {
            self.player.play()
        } else {
            self.player.pause()
        }
    }

    @IBAction func seekForward30(_ sender: Any) {
        self.player.setCurrentTime(self.player.currentTime + 30)
    }
    
    @IBAction func seekBack30(_ sender: Any) {
        self.player.setCurrentTime(self.player.currentTime - 30)
    }
    
    @IBAction func seekToSeconds(_ sender: Any) {
        guard let seconds = Double(seekSecondsTextField.text ?? "") else {
            return
        }
        self.player.setCurrentTime(seconds)
    }
        
    @IBAction func skipAd(_ sender: Any) {
        self.player.ads.skip()
    }
    
    func stop() {
        player.stop()
    }
}
