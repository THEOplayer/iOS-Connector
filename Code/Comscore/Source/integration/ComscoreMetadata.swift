//
//  ComscoreMetadata.swift
//
//  Copyright © THEOPlayer. All rights reserved.
//

import Foundation
import ComScore
/**
 Metadata object describing the content that is being played back
 */
@frozen
public struct ComScoreMetadata {
    let mediaType: SCORStreamingContentType
    let uniqueId: String
    let length: Int
    let c3: String?
    let c4: String?
    let c6: String?
    let stationTitle: String
    let stationCode: String?
    let networkAffiliate: String?
    let publisherName: String?
    let programTitle: String
    let programId: String?
    let episodeTitle: String
    let episodeId: String?
    let episodeSeasonNumber: String?
    let episodeNumber: String?
    let genreName: String
    let genreId: String?
    let carryTvAdvertisementLoad: Bool?
    let classifyAsCompleteEpisode: Bool?
    let productionDate: ComScoreDate? //TODO change content metadata builder in adapter
    let productionTime: ComScoreTime?
    let tvAirDate: ComScoreDate? //TODO check occurences with lowercase data & change content metadata builder in adapter
    let tvAirTime: ComScoreTime?
    let digitalAirDate: ComScoreDate? //TODO heck occurences with lowercase data & change content metadata builder in adapter
    let digitalAirTime: ComScoreTime?
    let feedType: SCORStreamingContentFeedType?
    let classifyAsAudioStream: Bool
    let deliveryMode: SCORStreamingContentDeliveryMode?
    let deliverySubscriptionType: SCORStreamingContentDeliverySubscriptionType?
    let deliveryComposition: SCORStreamingContentDeliveryComposition?
    let deliveryAdvertisementCapability: SCORStreamingContentDeliveryAdvertisementCapability?
    let mediaFormat: SCORStreamingContentMediaFormat?
    let distributionModel: SCORStreamingContentDistributionModel?
    let playlistTitle: String?
    let totalSegments: Int?
    let clipUrl: String?
    let videoDimension: Dimension?
    let customLabels: [String:String]?
    

    // MARK: - initializer
    /**
     Initialize a new ComScoreMetadata object
     */
    public init(mediaType: ComScoreMediaType,
                uniqueId: String,
                length: Int,
                c3: String? = nil,
                c4: String? = nil,
                c6: String? = nil,
                stationTitle: String,
                stationCode: String? = nil,
                networkAffiliate: String? = nil,
                publisherName: String? = nil,
                programTitle: String,
                programId: String? = nil,
                episodeTitle: String,
                episodeId: String? = nil,
                episodeSeasonNumber: String? = nil,
                episodeNumber: String? = nil,
                genreName: String,
                genreId: String? = nil,
                carryTvAdvertisementLoad: Bool? = nil,
                classifyAsCompleteEpisode: Bool? = nil,
                productionDate: ComScoreDate? = nil,
                productionTime: ComScoreTime? = nil,
                tvAirDate: ComScoreDate? = nil,
                tvAirTime: ComScoreTime? = nil,
                digitalAirDate: ComScoreDate? = nil,
                digitalAirTime: ComScoreTime? = nil,
                feedType: ComScoreFeedType? = nil,
                classifyAsAudioStream: Bool,
                deliveryMode: ComScoreDeliveryMode? = nil,
                deliverySubscriptionType: ComScoreDeliverySubscriptionType? = nil,
                deliveryComposition: ComScoreDeliveryComposition? = nil,
                deliveryAdvertisementCapability: ComScoreDeliveryAdvertisementCapability? = nil,
                mediaFormat: ComScoreMediaFormat? = nil,
                distributionModel: ComScoreDistributionModel? = nil,
                playlistTitle: String? = nil,
                totalSegments: Int? = nil,
                clipUrl: String? = nil,
                videoDimension: Dimension? = nil,
                customLabels: [String:String]? = [:]) {
        self.mediaType = mediaType.toComScore()
        self.uniqueId = uniqueId
        self.length = length
        self.c3 = c3
        self.c4 = c4
        self.c6 = c6
        self.stationTitle = stationTitle
        self.stationCode = stationCode
        self.networkAffiliate = networkAffiliate
        self.publisherName = publisherName
        self.programTitle = programTitle
        self.programId = programId
        self.episodeTitle = episodeTitle
        self.episodeId = episodeId
        self.episodeSeasonNumber = episodeSeasonNumber
        self.episodeNumber = episodeNumber
        self.genreName = genreName
        self.genreId = genreId
        self.carryTvAdvertisementLoad = carryTvAdvertisementLoad
        self.classifyAsCompleteEpisode = classifyAsCompleteEpisode
        self.productionDate = productionDate
        self.productionTime = productionTime
        self.tvAirDate = tvAirDate
        self.tvAirTime = tvAirTime
        self.digitalAirDate = digitalAirDate
        self.digitalAirTime = digitalAirTime
        self.feedType = feedType?.toComScore()
        self.classifyAsAudioStream = classifyAsAudioStream
        self.deliveryMode = deliveryMode?.toComScore()
        self.deliverySubscriptionType = deliverySubscriptionType?.toComScore()
        self.deliveryComposition = deliveryComposition?.toComScore()
        self.deliveryAdvertisementCapability = deliveryAdvertisementCapability?.toComScore()
        self.mediaFormat = mediaFormat?.toComsScore()
        self.distributionModel = distributionModel?.toComsScore()
        self.playlistTitle = playlistTitle
        self.totalSegments = totalSegments
        self.clipUrl = clipUrl
        self.videoDimension = videoDimension
        self.customLabels = customLabels
    }
}
