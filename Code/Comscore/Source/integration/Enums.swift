//
//  theoComscoreUserConsent.swift
//  theoplayer-comscore-ios-integration
//
//  Copyright © 2021 THEOPlayer. All rights reserved.
//

import Foundation
import ComScore

@frozen
public enum ComScoreUserConsent: String {
    case denied = "0"
    case granted = "1"
    case unknown = "-1"
}

/**
 ComScoreMediaType associated with the content you have loaded into the THEOPlayer
 */
@frozen
public enum ComScoreMediaType: String {
    case longFormOnDemand
    case shortFormOnDemand
    case live
    case userGeneratedLongFormOnDemand
    case userGeneratedShortFormOnDemand
    case userGeneratedLive
    case bumper
    case other

    func toComScore() -> SCORStreamingContentType {
        switch self {
        case .longFormOnDemand:
            return .longFormOnDemand
        case .shortFormOnDemand:
            return .shortFormOnDemand
        case .live:
            return .live
        case .userGeneratedLongFormOnDemand:
            return .userGeneratedLongFormOnDemand
        case .userGeneratedShortFormOnDemand:
            return .userGeneratedShortFormOnDemand
        case .userGeneratedLive:
            return .userGeneratedLive
        case .bumper:
            return .bumper
        case .other:
            return .other
        }
    }
}

@frozen
public enum ComScoreFeedType: String {
    case eastHD
    case westHD
    case eastSD
    case westSD
    
    func toComScore() -> SCORStreamingContentFeedType {
        switch self {
        case .eastHD:
            return .eastHD
        case .westHD:
            return .westHD
        case .eastSD:
            return .eastSD
        case .westSD:
            return .westSD
        }
    }
}

@frozen
public enum ComScoreDeliveryMode: String {
    case linear
    case ondemand
    
    func toComScore() -> SCORStreamingContentDeliveryMode {
        switch self {
        case .linear:
            return .linear
        case .ondemand:
            return .ondemand
        }
    }
}

@frozen
public enum ComScoreDeliverySubscriptionType: String {
    case traditionalMvpd    // LIVE
    case virtualMvpd        //LIVE
    case subscription
    case transactional
    case advertising
    case premium

    func toComScore() -> SCORStreamingContentDeliverySubscriptionType {
        switch self {
        case .traditionalMvpd:
            return .traditionalMvpd
        case .virtualMvpd:
            return .virtualMvpd
        case .subscription:
            return .subscription
        case .transactional:
            return .transactional
        case .advertising:
            return .advertising
        case .premium:
            return .premium
        }
    }
}

@frozen
public enum ComScoreDeliveryComposition: String {
    case clean
    case embed
    
    func toComScore() -> SCORStreamingContentDeliveryComposition {
        switch self {
        case .clean:
            return .clean
        case .embed:
            return .embed
        }
    }
}

@frozen
public enum ComScoreDeliveryAdvertisementCapability: String {
    case none
    case dynamicLoad
    case dynamicReplacement
    case linear1day
    case linear2day
    case linear3day
    case linear4day
    case linear5day
    case linear6day
    case linear7day
    
    func toComScore() -> SCORStreamingContentDeliveryAdvertisementCapability {
        switch self {
        case .none:
            return .none
        case .dynamicLoad:
            return .dynamicLoad
        case .dynamicReplacement:
            return .dynamicReplacement
        case .linear1day:
            return .linear1day
        case .linear2day:
            return .linear2day
        case .linear3day:
            return .linear3day
        case .linear4day:
            return .linear4day
        case .linear5day:
            return .linear5day
        case .linear6day:
            return .linear6day
        case .linear7day:
            return .linear7day
        }
    }
}

@frozen
public enum ComScoreMediaFormat: String {
    case fullContentEpisode
    case fullContentMovie
    case fullContentPodcast
    case fullContentGeneric
    case partialContentEpisode
    case partialContentMovie
    case partialContentPodcast
    case partialContentGeneric
    case previewEpisode
    case previewMovie
    case previewGeneric
    case extraEpisode
    case extraMovie
    case extraGeneric
    
    func toComsScore() -> SCORStreamingContentMediaFormat {
        switch self {
        case .fullContentEpisode:
            return .fullContentEpisode
        case .fullContentMovie:
            return .fullContentMovie
        case .fullContentPodcast:
            return .fullContentPodcast
        case .fullContentGeneric:
            return .fullContentGeneric
        case .partialContentEpisode:
            return .partialContentEpisode
        case .partialContentMovie:
            return .partialContentMovie
        case .partialContentPodcast:
            return .partialContentPodcast
        case .partialContentGeneric:
            return .partialContentGeneric
        case .previewEpisode:
            return .previewEpisode
        case .previewMovie:
            return .previewMovie
        case .previewGeneric:
            return .previewGeneric
        case .extraEpisode:
            return .extraEpisode
        case .extraMovie:
            return .extraMovie
        case .extraGeneric:
            return .extraGeneric
        }
    }
}

@frozen
public enum ComScoreDistributionModel: String {
    case tvAndOnline
    case exclusivelyOnline
    
    func toComsScore() -> SCORStreamingContentDistributionModel {
        switch self {
        case .tvAndOnline:
            return .tvAndOnline
        case .exclusivelyOnline:
            return .exclusivelyOnline
        }
    }
}
