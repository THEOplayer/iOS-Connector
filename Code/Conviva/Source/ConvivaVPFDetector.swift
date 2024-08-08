//
//  ConvivaVPFDetector.swift
//

import Foundation
import AVFoundation
import THEOplayerSDK

/// Detects failures during video playback. This is a **TEMPORARY AVPlayer BUG WORKAROUND**
///
/// Create an instance, feed it events and it will decide if AVPlayer is locked into a failed state.
///
/// First observe THEOplayer events:
///  - `PlayerEventTypes.WAITING` → transitionToWaiting()
///  - `PlayerEventTypes.SOURCE_CHANGE` → reset()
///  - `PlayerEventTypes.PLAYING` → reset()
///  - `PlayerEventTypes.PROGRESS` → reset()
///  - `PlayerEventTypes.ENDED` → reset()
///
/// on transitionToWaiting set out a timer that when fired checks the errorLog for severe events.


protocol VPFDetectordelegate: AnyObject {
    func onVPFDetected()
}

let VPF_STALL_INTERVAL: TimeInterval = 25.0
let DEBUG_VPF = false

class ConvivaVPFDetector {
    weak var player: THEOplayer?
    weak var delegate: VPFDetectordelegate?
    private var lastMarkedReset: TimeInterval?
    private var stallCheckTimer: Timer?
    private let errorCountTreshold = 5
    private var videoPlaybackFailureCallback: (([String: Any]) -> Void)?
    private let vpfErrorDictionary = [
        "error": [
            "errorCode": String(THEOErrorCode.NETWORK_TIMEOUT.rawValue),
            "errorMessage": "Network Timeout"
        ]
    ]
    
    func transitionToWaiting() {
        guard self.stallCheckTimer == nil else {
            // already in a waiting state...
            self.vpfLog("Already checking the waiting state...")
            return
        }
        
        self.stallCheckTimer = Timer.scheduledTimer(withTimeInterval: VPF_STALL_INTERVAL, repeats: false, block: { [weak self] timer in
            if let welf = self,
               let player = welf.player,
               let currentItem = player.currentItem,
               let errorLog = currentItem.errorLog() {
                welf.checkForVPF(log: errorLog)
                self?.stallCheckTimer = nil
            }
        })
        self.vpfLog("Transitioned to waiting.")
    }
    
    func reset() {
        // Store last VPF reset timestamp
        self.lastMarkedReset = Date().timeIntervalSince1970
        
        if self.stallCheckTimer != nil {
            self.stallCheckTimer?.invalidate()
            self.stallCheckTimer = nil;
            self.vpfLog("Detector is reset.")
        }
    }

    func checkForVPF(log: AVPlayerItemErrorLog) {
        var errorCountWithinDetectionRange = 0
        for event in log.events {
            if event.kind.isSevere,
               let eventTimestamp = event.date?.timeIntervalSince1970,
               let lastResetTimestamp = self.lastMarkedReset,
               eventTimestamp > lastResetTimestamp {
                self.vpfLog("Severe errorLog event found at \((eventTimestamp - lastResetTimestamp)) sec from reset. (\(event.errorComment ?? "no comment"))")
                errorCountWithinDetectionRange += 1
            }
        }
        let nowT = Date().timeIntervalSince1970
        let detectionRange = nowT - (self.lastMarkedReset ?? nowT)
        if errorCountWithinDetectionRange >= self.errorCountTreshold {
            self.vpfLog("VPF detected. \(errorCountWithinDetectionRange) severe errors within detection range (last \(detectionRange) sec).")
            self.videoPlaybackFailureCallback?(self.vpfErrorDictionary)
            self.delegate?.onVPFDetected()
        } else {
            self.vpfLog("Stall interpreted as not caused by network error. Only \(errorCountWithinDetectionRange) severe errors within detection range (last \(detectionRange) sec).")
        }
    }
    
    func setVideoPlaybackFailureCallback(_ videoPlaybackFailureCallback: (([String: Any]) -> Void)? ) {
        self.videoPlaybackFailureCallback = videoPlaybackFailureCallback
    }
    
    private func vpfLog(_ logString: String) {
        if DEBUG_VPF {
            print("[DEBUG-VPF]", logString)
        }
    }
}

extension ConvivaVPFDetector {
    struct NetworkEventKind: Hashable {
        let domain: String
        let code: Int
        
        var isSevere: Bool { Self.severeErrors.contains(self) }
        
        static var severeErrors = Set([
            Self(domain: NSURLErrorDomain, code: URLError.Code.secureConnectionFailed.rawValue),
            Self(domain: NSURLErrorDomain, code: URLError.Code.cannotFindHost.rawValue),
            Self(domain: NSURLErrorDomain, code: URLError.Code.cannotConnectToHost.rawValue),
            Self(domain: NSURLErrorDomain, code: URLError.Code.networkConnectionLost.rawValue),
            Self(domain: "CoreMediaErrorDomain", code: -12938), // 404: File Not Found
            Self(domain: "CoreMediaErrorDomain", code: -12660), // 403: Forbidden
            Self(domain: "CoreMediaErrorDomain", code: -12661), // 503: Unavailable
            Self(domain: "CoreMediaErrorDomain", code: -16840), // 401: Unauthorized. iOS11
            Self(domain: "CoreMediaErrorDomain", code: -12937), // Authentication Error
            Self(domain: "CoreMediaErrorDomain", code: -12666), // Unrecognized http response
            Self(domain: "CoreMediaErrorDomain", code: -12971), // The operation couldn’t be completed   failed to parse segment as either an MPEG-2 TS or an ES
        ])
    }
}

extension AVPlayerItemErrorLogEvent {
    var kind: ConvivaVPFDetector.NetworkEventKind {
        .init(domain: errorDomain, code: errorStatusCode)
    }
}
