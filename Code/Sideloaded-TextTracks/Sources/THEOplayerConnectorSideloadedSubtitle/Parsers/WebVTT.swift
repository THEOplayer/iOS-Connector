//
//  WebVTT.swift
//  SideloadedTextTracks
//
//  Created by Raffi on 02/05/2024.
//

import Foundation

struct WebVTT {
    struct WebVTTCue {
        let startTime: TimeInterval
        let endTime: TimeInterval
        let text: String
    }

    let cues: [WebVTTCue]

    init(webVttContent: String) {
        self.cues = Self.cues(from: webVttContent)
    }

    private static func cues(from webVttContent: String) -> [WebVTTCue] {
        var cues: [WebVTTCue] = []
        var currentCueStartTime: TimeInterval?
        var currentCueEndTime: TimeInterval?
        var currentCueText = ""

        // Loop over all the lines in the VTT file
        for line in webVttContent.components(separatedBy: .newlines) {
            // Finds lines where a cue's time values are located and stores the start and end times
            let timePattern: String = #"(\d{2}:)?(\d{2}:\d{2}\.\d{3}) --> (\d{2}:)?(\d{2}:\d{2}\.\d{3})"#
            if let match: NSTextCheckingResult = line.firstMatch(pattern: timePattern),
               let startTimeStr: String = line.substring(with: match.range(at: 1)),
               let endTimeStr: String = line.substring(with: match.range(at: 2)),
               let startTime: TimeInterval = Self.timeInterval(from: startTimeStr),
               let endTime: TimeInterval = Self.timeInterval(from: endTimeStr) {
                currentCueStartTime = startTime
                currentCueEndTime = endTime
            } else {
                // A new line represents the end of a cue in a VTT file.
                // Checks if text, start time, and end time values are retreived.
                // If all values are present then add a cue.
                if line.isEmpty {
                    if let startTime: TimeInterval = currentCueStartTime,
                       let endTime: TimeInterval = currentCueEndTime,
                       !currentCueText.isEmpty {
                        let webVttCue: WebVTTCue = .init(
                            startTime: startTime,
                            endTime: endTime,
                            text: currentCueText.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        cues.append(webVttCue)
                    }
                    currentCueStartTime = nil
                    currentCueEndTime = nil
                    currentCueText = ""
                } else {
                    // If the line is not empty (not end of cue)
                    // and if start time is already retreived
                    // then we are on the content text line. Store the value.
                    if currentCueStartTime != nil {
                        currentCueText += line + "\n"
                    }
                }
            }
        }

        // In case where the file does not end with an empty line
        // then we add the final cue if needed (if values are present).
        if let startTime: TimeInterval = currentCueStartTime,
           let endTime: TimeInterval = currentCueEndTime,
           !currentCueText.isEmpty {
            let webVttCue: WebVTTCue = .init(
                startTime: startTime,
                endTime: endTime,
                text: currentCueText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            cues.append(webVttCue)
        }

        return cues
    }

    private static func timeInterval(from string: String) -> TimeInterval? {
        let components: [String] = string.components(separatedBy: ":")
        guard components.count >= 3,
              let hours: Double = .init(components[0]),
              let minutes: Double = .init(components[1]),
              let seconds: Double = .init(components[2]) else {
            return nil
        }

        let totalSeconds: Double = (hours * 3600) + (minutes * 60) + seconds
        return totalSeconds
    }
}
