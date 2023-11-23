//
//  Enums.swift
//
//  Copyright © THEOPlayer. All rights reserved.
//

import Foundation
import ComScore

@frozen
public enum ComScoreUserConsent: String {
    case denied = "0"
    case granted = "1"
    case unknown = "-1"
}

@frozen
public enum ComscoreUsagePropertiesAutoUpdateMode: String {
    case foregroundOnly
    case foregroundAndBackground
    case disabled
    
    func toComscore() -> SCORUsagePropertiesAutoUpdateMode {
        switch self {
        case .foregroundOnly:
            return SCORUsagePropertiesAutoUpdateMode.foregroundOnly
        case .foregroundAndBackground:
            return SCORUsagePropertiesAutoUpdateMode.foregroundAndBackground
        case .disabled:
            return SCORUsagePropertiesAutoUpdateMode.disabled
        }
    }
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
            return SCORStreamingContentType.longFormOnDemand
        case .shortFormOnDemand:
            return SCORStreamingContentType.shortFormOnDemand
        case .live:
            return SCORStreamingContentType.live
        case .userGeneratedLongFormOnDemand:
            return SCORStreamingContentType.userGeneratedLongFormOnDemand
        case .userGeneratedShortFormOnDemand:
            return SCORStreamingContentType.userGeneratedShortFormOnDemand
        case .userGeneratedLive:
            return SCORStreamingContentType.userGeneratedLive
        case .bumper:
            return SCORStreamingContentType.bumper
        case .other:
            return SCORStreamingContentType.other
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
            return SCORStreamingContentFeedType.eastHD
        case .westHD:
            return SCORStreamingContentFeedType.westHD
        case .eastSD:
            return SCORStreamingContentFeedType.eastSD
        case .westSD:
            return SCORStreamingContentFeedType.westSD
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
            return SCORStreamingContentDeliveryMode.linear
        case .ondemand:
            return SCORStreamingContentDeliveryMode.ondemand
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
            return SCORStreamingContentDeliverySubscriptionType.traditionalMvpd
        case .virtualMvpd:
            return SCORStreamingContentDeliverySubscriptionType.virtualMvpd
        case .subscription:
            return SCORStreamingContentDeliverySubscriptionType.subscription
        case .transactional:
            return SCORStreamingContentDeliverySubscriptionType.transactional
        case .advertising:
            return SCORStreamingContentDeliverySubscriptionType.advertising
        case .premium:
            return SCORStreamingContentDeliverySubscriptionType.premium
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
            return SCORStreamingContentDeliveryComposition.clean
        case .embed:
            return SCORStreamingContentDeliveryComposition.embed
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
            return SCORStreamingContentDeliveryAdvertisementCapability.none
        case .dynamicLoad:
            return SCORStreamingContentDeliveryAdvertisementCapability.dynamicLoad
        case .dynamicReplacement:
            return SCORStreamingContentDeliveryAdvertisementCapability.dynamicReplacement
        case .linear1day:
            return SCORStreamingContentDeliveryAdvertisementCapability.linear1day
        case .linear2day:
            return SCORStreamingContentDeliveryAdvertisementCapability.linear2day
        case .linear3day:
            return SCORStreamingContentDeliveryAdvertisementCapability.linear3day
        case .linear4day:
            return SCORStreamingContentDeliveryAdvertisementCapability.linear4day
        case .linear5day:
            return SCORStreamingContentDeliveryAdvertisementCapability.linear5day
        case .linear6day:
            return SCORStreamingContentDeliveryAdvertisementCapability.linear6day
        case .linear7day:
            return SCORStreamingContentDeliveryAdvertisementCapability.linear7day
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
            return SCORStreamingContentMediaFormat.fullContentEpisode
        case .fullContentMovie:
            return SCORStreamingContentMediaFormat.fullContentMovie
        case .fullContentPodcast:
            return SCORStreamingContentMediaFormat.fullContentPodcast
        case .fullContentGeneric:
            return SCORStreamingContentMediaFormat.fullContentGeneric
        case .partialContentEpisode:
            return SCORStreamingContentMediaFormat.partialContentEpisode
        case .partialContentMovie:
            return SCORStreamingContentMediaFormat.partialContentMovie
        case .partialContentPodcast:
            return SCORStreamingContentMediaFormat.partialContentPodcast
        case .partialContentGeneric:
            return SCORStreamingContentMediaFormat.partialContentGeneric
        case .previewEpisode:
            return SCORStreamingContentMediaFormat.previewEpisode
        case .previewMovie:
            return SCORStreamingContentMediaFormat.previewMovie
        case .previewGeneric:
            return SCORStreamingContentMediaFormat.previewGeneric
        case .extraEpisode:
            return SCORStreamingContentMediaFormat.extraEpisode
        case .extraMovie:
            return SCORStreamingContentMediaFormat.extraMovie
        case .extraGeneric:
            return SCORStreamingContentMediaFormat.extraGeneric
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
            return SCORStreamingContentDistributionModel.tvAndOnline
        case .exclusivelyOnline:
            return SCORStreamingContentDistributionModel.exclusivelyOnline
        }
    }
}
