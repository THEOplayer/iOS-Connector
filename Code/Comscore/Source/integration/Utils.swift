//
//  Utils.swift
//  THEOplayer-Connector-Comscore
//
//  Created by Wonne Joosen on 13/03/2023.
//

import Foundation

public struct ComScoreTime {
    let hours: Int
    let minutes: Int
    init(hours: Int, minutes: Int) {
        self.hours = hours
        self.minutes = minutes
    }
}

public struct ComScoreDate {
    let year: Int
    let month: Int
    let day: Int
    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
}

public struct Dimension {
    let width: Int
    let height: Int
    init(width: Int, height: Int, day: Int) {
        self.width = width
        self.height = height
    }
}
