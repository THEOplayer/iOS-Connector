//
//  AVAudioSessionExtensions.swift
//
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioSession {
    func isConnectedToAirplayDevice () -> Bool {
        let currentRoute: AVAudioSessionRouteDescription = self.currentRoute
        for outputPort: AVAudioSessionPortDescription in currentRoute.outputs {
            if outputPort.portType == .airPlay {
                return true
            }
        }

        return false
    }
}
