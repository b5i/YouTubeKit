//
//  YTVideo+decodeVideoFromPlaylist.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 28.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YTVideo {
    /// Decode a certain type of JSON dictionnary called "playlistVideoRenderer" or "playlistVideoListRenderer"
    /// - Parameter json: the JSON to be decoded.
    /// - Returns: A YTVideo if the decoding was successful or nil if it wasn't.
    static func decodeVideoFromPlaylist(json: JSON) -> YTVideo? {
        /// Check if the JSON can be decoded as a Video.
        guard let videoId = json["videoId"].string else { return nil }
        
        /// Inititalize a new ``YTSearchResultType/Video-swift.struct`` instance to put the informations in it.
        var video = YTVideo(videoId: videoId)
                    
        if json["title", "simpleText"].string != nil {
            video.title = json["title", "simpleText"].string
        } else if let titleArray = json["title", "runs"].array {
            video.title = titleArray.map({$0["text"].stringValue}).joined()
        }
        
        if let channelId = json["shortBylineText", "runs", 0, "navigationEndpoint", "browseEndpoint", "browseId"].string {
            
            video.channel = YTLittleChannelInfos(channelId: channelId, name: json["shortBylineText", "runs", 0, "text"].string)
        }
        
        video.viewCount = json["videoInfo", "runs", 0, "text"].string
        
        video.timePosted = json["videoInfo", "runs", 2, "text"].string
                
        if let timeLength = json["lengthText", "simpleText"].string {
            video.timeLength = timeLength
        } else {
            video.timeLength = "live"
        }
        
        YTThumbnail.appendThumbnails(json: json["thumbnail"], thumbnailList: &video.thumbnails)
        
        return video
    }
}
