//
//  AssetInfoResponse.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 11/2/2025.
//

import Foundation

public struct BoundaryDetails: Codable, Equatable {
    let duration: Double
    let offset: Double
}

public struct ThumbNailResolution: Codable, Equatable {
    let width: Int?
    let height: Int?
    let bw: Int
    let bh: Int
    let prefix: String
}

public struct AssetInfoResponse: Codable, Equatable {
    
    /// Returns 1 when the asset has been flagged as audio only. Valid values are: 0 or 1
    let audioOnly: Int
    
    /// Indicates the offset and duration, in seconds, for each boundary in the asset.
    let boundaryDetails: [BoundaryDetails]? 
    
    /// Returns 1 when an error occurred with the asset. Valid values are: 0 or 1
    let error: Int
    
    /// Indicates the asset's TV rating. Valid values are:
    /// -1: Not Available
    /// 0: Not Rated
    /// 1: TV-Y
    /// 2: TV-Y7
    /// 3: TV-G
    /// 4: TV-PG
    /// 5: TV-14
    /// 6: TV-MA
    /// 7: Not Rated
    let tvRating: Int
    
    /// Indicates the total number of slices available for this asset.
    let maxSlice: Int
    
    /// Indicates the base URL for thumbnails.
    let thumbPrefix: String
 
    /// Indicates the average duration, in seconds, for each slice.
    let sliceDur: Double
    
    /// Indicates the asset's movie rating. Valid values are:
    /// -1: Not Available
    /// 0: Not Applicable
    /// 1: G
    /// 2: PG
    /// 3: PG-13
    /// 4: R
    /// 5: NC-17
    /// 6: X
    /// 7: Not Rated
    let movieRating: Int
    
    /// Indicates the user ID for the asset's owner.
    let owner: String
    
    /// Returns the asset's metadata.
    let meta: [String: String]
    
    /// Reports the asset's available bitrates as a collection of number values.
    let rates: [Int]
    
    /// Contains an object for each available thumbnail resolution.
    let thumbs: [ThumbNailResolution]
    
    
    /// Indicates the URL for the poster image.
    let posterUrl: String
    
    /// Indicates the asset's duration in seconds.
    let duration: Double
    
    /// Indicates the permanent URL to the asset's default poster image.
    let defaultPosterUrl: String
    
    /// Indicates the asset's description.
    let desc: String
    
    /// Indicates the set of rating flags assigned to the asset via a number derived from a bitwise operation on rating flags (DLSV). Sample values are provided below.
    /// 0: No rating flags
    /// 1: Coarse or crude language flag (L)
    /// 2: Sexual situations flag (S)
    /// 4: Violence flag (V)
    /// 8: Suggestive dialog flag (D)
    /// 15: All rating flags (DLSV)
    let ratingFlags: Int
    
    /// Indicates the asset's external ID.
    let externalId: String

    /// Returns 1 when the asset has been flagged as an ad. Valid values are: 0 or 1
    let isAd: Int
    
    /// Indicates the asset's system-defined ID.
    let asset: String
}
