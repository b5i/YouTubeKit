//
//  YTVideo+decodeShortFromJSON.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 24.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YTVideo {
    /// Process the JSON and give a decoded version of it.
    /// - Parameter json: the JSON to be decoded, should have a "videoId" directly in it.
    /// - Returns: An instance of YTVideo, that is actually representing a short.
    ///
    /// The informations about shorts are very little compared to the informations you would get with a normal video.
    static func decodeShortFromJSON(json: JSON) -> YTVideo? {
        /// Check if the JSON can be decoded as a Video.
        guard let videoId = json["videoId"].string else { return nil }
        
        /// Inititalize a new ``YTSearchResultType/Video-swift.struct`` instance to put the informations in it.
        var video = YTVideo(videoId: videoId)
                    
        video.title = json["headline", "simpleText"].string
                
        video.viewCount = json["viewCountText", "simpleText"].string
        
        YTThumbnail.appendThumbnails(json: json["thumbnail"], thumbnailList: &video.thumbnails)
        
        return video
    }
    
    // Process the JSON and give a decoded version of it.
    /// - Parameter json: the JSON to be decoded, should be a `shortsLockupViewModel`.
    /// - Returns: An instance of YTVideo, that is actually representing a short.
    ///
    /// The informations about shorts are very little compared to the informations you would get with a normal video.
    static func decodeShortFromLockupJSON(json: JSON) -> YTVideo? {
        guard let videoId = json["onTap", "innertubeCommand", "reelWatchEndpoint", "videoId"].string else { return nil }
        
        var video = YTVideo(videoId: videoId)
        
        video.title = json["overlayMetadata", "primaryText", "content"].string
        
        video.viewCount = json["overlayMetadata", "secondaryText", "content"].string
        
        YTThumbnail.appendThumbnails(json: json["thumbnail"], thumbnailList: &video.thumbnails)
        
        return video
    }
}
