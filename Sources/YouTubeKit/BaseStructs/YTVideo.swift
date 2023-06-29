//
//  YTVideo.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a video.
public struct YTVideo: YTSearchResult, YouTubeVideo, Codable {
    public static func == (lhs: YTVideo, rhs: YTVideo) -> Bool {
        return lhs.channel.channelId == rhs.channel.channelId && lhs.channel.name == rhs.channel.name && lhs.thumbnails == rhs.thumbnails && lhs.timeLength == rhs.timeLength && lhs.timePosted == rhs.timePosted && lhs.title == rhs.title && lhs.videoId == rhs.videoId && lhs.viewCount == rhs.viewCount
    }
    
    public static func canBeDecoded(json: JSON) -> Bool {
        return json["videoId"].string != nil
    }
    
    public static func decodeJSON(json: JSON) -> YTVideo? {
        /// Check if the JSON can be decoded as a Video.
        guard let videoId = json["videoId"].string else { return nil }
        
        /// Inititalize a new ``YTSearchResultType/Video-swift.struct`` instance to put the informations in it.
        var video = YTVideo(videoId: videoId)
                    
        if json["title"]["simpleText"].string != nil {
            video.title = json["title"]["simpleText"].string
        } else if let titleArray = json["title"]["runs"].array {
            var title: String = ""
            for titlePart in titleArray {
                title += titlePart["text"].stringValue
            }
            video.title = title
        }
        
        video.channel.name = json["ownerText"]["runs"][0]["text"].string
        video.channel.channelId = json["ownerText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string
        
        YTThumbnail.appendThumbnails(json: json["channelThumbnailSupportedRenderers"]["channelThumbnailWithLinkRenderer"], thumbnailList: &video.channel.thumbnails)
        
        if let viewCount = json["shortViewCountText"]["simpleText"].string {
            video.viewCount = viewCount
        } else {
            var viewCount: String = ""
            for viewCountTextPart in json["shortViewCountText"]["runs"].array ?? [] {
                viewCount += viewCountTextPart["text"].string ?? ""
            }
            video.viewCount = viewCount
        }
        
        video.timePosted = json["publishedTimeText"]["simpleText"].string
        
        if let timeLength = json["lengthText"]["simpleText"].string {
            video.timeLength = timeLength
        } else {
            video.timeLength = "live"
        }
        
        YTThumbnail.appendThumbnails(json: json, thumbnailList: &video.thumbnails)
        
        return video
    }
    
    public static var type: YTSearchResultType = .video
    
    public var id: Int?

    
    public var videoId: String
    
    /// Video's title.
    public var title: String?
    
    /// Channel informations.
    ///
    /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
    public var channel: YTLittleChannelInfos = .init()
    
    /// Number of views of the video, in a shortened string.
    ///
    /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
    public var viewCount: String?
    
    /// String representing the moment when the video was posted.
    ///
    /// Usually like `posted 3 months ago`.
    ///
    /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
    public var timePosted: String?
    
    /// String representing the duration of the video.
    ///
    /// Can be `live` instead of `ab:cd` if the video is a livestream.
    public var timeLength: String?
    
    /// Array of thumbnails.
    ///
    /// Usually sorted by resolution, from low to high.
    ///
    /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
    public var thumbnails: [YTThumbnail] = []
    
    ///Not necessary here because of prepareJSON() method
    /*
    enum CodingKeys: String, CodingKey {
        case videoId
        case title
        case channel
        case viewCount
        case timePosted
        case timeLength
        case thumbnails
    }
     */
}
