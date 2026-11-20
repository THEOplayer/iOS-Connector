//
//  PlayerView.swift
//  GemiusReporter
//
//  Created by Joosen, Wonne on 07/07/2025.
//

import UIKit
import THEOplayerSDK

/// A container UIView that holds a `THEOPlayer` and lays it out
/// to stretch the entire frame of this container view
class PlayerView: UIView {
    /// The player that is streched out to fit this view
    let player: THEOplayer
    
    required init?(coder: NSCoder) {nil}
    
    /// Create a container view that holds a `THEOPlayer` and lays it out
    /// to stretch its contents to fill the entire frame of the container view.
    /// - Parameter player: The player that will be laid out in this view
    init(player: THEOplayer) {
        self.player = player
        super.init(frame: player.frame)
        player.addAsSubview(of: self)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        player.frame = bounds
    }
}
