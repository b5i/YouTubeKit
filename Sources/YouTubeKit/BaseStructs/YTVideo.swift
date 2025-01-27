//
//  YTVideo.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a video.
public struct YTVideo: YTSearchResult, YouTubeVideo, Codable, Sendable {
    public init(id: Int? = nil, videoId: String, title: String? = nil, channel: YTLittleChannelInfos? = nil, viewCount: String? = nil, timePosted: String? = nil, timeLength: String? = nil, thumbnails: [YTThumbnail] = []) {
        self.id = id
        self.videoId = videoId
        self.title = title
        self.channel = channel
        self.viewCount = viewCount
        self.timePosted = timePosted
        self.timeLength = timeLength
        self.thumbnails = thumbnails
    }
    
    public static func == (lhs: YTVideo, rhs: YTVideo) -> Bool {
        return lhs.channel?.channelId == rhs.channel?.channelId && lhs.channel?.name == rhs.channel?.name && lhs.thumbnails == rhs.thumbnails && lhs.timeLength == rhs.timeLength && lhs.timePosted == rhs.timePosted && lhs.title == rhs.title && lhs.videoId == rhs.videoId && lhs.viewCount == rhs.viewCount
    }
    
    public static func canBeDecoded(json: JSON) -> Bool {
        return json["videoId"].string != nil || json["onTap"]["innertubeCommand"]["reelWatchEndpoint"]["videoId"].string != nil || json["contentType"].string == "LOCKUP_CONTENT_TYPE_VIDEO"
    }
    
    public static func decodeJSON(json: JSON) -> YTVideo? {
        /// Check if the JSON can be decoded as a Video.
        guard let videoId = json["videoId"].string else { return nil }
        
        /// Inititalize a new ``YTSearchResultType/Video-swift.struct`` instance to put the informations in it.
        var video = YTVideo(videoId: videoId)
                    
        if json["title"]["simpleText"].string != nil {
            video.title = json["title"]["simpleText"].string
        } else if let titleArray = json["title"]["runs"].array {
            video.title = titleArray.map({$0["text"].stringValue}).joined()
        }
        
        if let channelId = json["ownerText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string {
            var channel = YTLittleChannelInfos(channelId: channelId, name: json["ownerText"]["runs"][0]["text"].string)
            YTThumbnail.appendThumbnails(json: json["channelThumbnailSupportedRenderers"]["channelThumbnailWithLinkRenderer"]["thumbnail"], thumbnailList: &channel.thumbnails)
            
            video.channel = channel
        } else if let channelId = json["longBylineText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string {
            var channel = YTLittleChannelInfos(channelId: channelId, name: json["longBylineText"]["runs"][0]["text"].string)
            YTThumbnail.appendThumbnails(json: json["channelThumbnailSupportedRenderers"]["channelThumbnailWithLinkRenderer"]["thumbnail"], thumbnailList: &channel.thumbnails)
            
            video.channel = channel
        } else if let channelId = json["shortBylineText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string {
            var channel = YTLittleChannelInfos(channelId: channelId, name: json["shortBylineText"]["runs"][0]["text"].string)
            YTThumbnail.appendThumbnails(json: json["channelThumbnailSupportedRenderers"]["channelThumbnailWithLinkRenderer"]["thumbnail"], thumbnailList: &channel.thumbnails)
            
            video.channel = channel
        }
        
        if let viewCount = json["shortViewCountText"]["simpleText"].string {
            video.viewCount = viewCount
        } else {
            video.viewCount = json["shortViewCountText"]["runs"].arrayValue.map({$0["text"].stringValue}).joined()
        }
        
        video.timePosted = json["publishedTimeText"]["simpleText"].string
        
        if let timeLength = json["lengthText"]["simpleText"].string {
            video.timeLength = timeLength
        } else {
            video.timeLength = "live"
        }
        
        YTThumbnail.appendThumbnails(json: json["thumbnail"], thumbnailList: &video.thumbnails)
        
        return video
    }
    
    /// Give a `lockupViewModel` to decode.
    public static func decodeLockupJSON(json: JSON) -> YTVideo? {
        guard let videoId = json["contentId"].string, json["contentType"] == "LOCKUP_CONTENT_TYPE_VIDEO" else { return nil }
        
        var video = YTVideo(videoId: videoId)
        
        video.title = json["metadata"]["lockupMetadataViewModel"]["title"]["content"].string
                   
        let metadataRows = json["metadata"]["lockupMetadataViewModel"]["metadata"]["contentMetadataViewModel"]["metadataRows"]
        
        if let channelJSON = metadataRows.array?.first(where: { $0["metadataParts"].array?.first?["text"]["commandRuns"].array?.first?["onTap"]["innertubeCommand"]["commandMetadata"]["webCommandMetadata"]["webPageType"].string == "WEB_PAGE_TYPE_CHANNEL" }) ?? metadataRows.array?.first {
            let channelId = channelJSON["metadataParts"].array?.first?["text"]["commandRuns"].array?.first?["onTap"]["innertubeCommand"]["browseEndpoint"]["browseId"].string ?? ""
            video.channel = YTLittleChannelInfos(channelId: channelId, name: channelJSON["metadataParts"].array?.first?["text"]["content"].string)
            YTThumbnail.appendThumbnails(json: json["metadata"]["lockupMetadataViewModel"]["image"]["decoratedAvatarViewModel"]["avatar"]["avatarViewModel"], thumbnailList: &video.channel!.thumbnails)
        }
            
        let viewCountAndDateJSON = metadataRows.array?.filter({ $0["metadataParts"].array?.first?["text"]["commandRuns"].array?.first?["onTap"]["innertubeCommand"]["commandMetadata"]["webCommandMetadata"]["webPageType"].string != "WEB_PAGE_TYPE_CHANNEL" || $0["badges"].exists() }).last
        
        video.viewCount = viewCountAndDateJSON?["metadataParts"].array?.first?["text"]["content"].string
        video.timePosted = viewCountAndDateJSON?["metadataParts"].array?.last?["text"]["content"].string
        
        YTThumbnail.appendThumbnails(json: json["contentImage"]["thumbnailViewModel"], thumbnailList: &video.thumbnails)
        
        video.timeLength = json["contentImage"]["thumbnailViewModel"]["overlays"].array?.first?["thumbnailOverlayBadgeViewModel"]["thumbnailBadges"].array?.first?["thumbnailBadgeViewModel"]["text"].string
        
        return video
    }
    
    public static let type: YTSearchResultType = .video
    
    public var id: Int?

    
    public var videoId: String
    
    /// Video's title.
    public var title: String?
    
    /// Channel informations.
    ///
    /// Possibly not defined when reading in ``YTPlaylist/frontVideos`` properties.
    public var channel: YTLittleChannelInfos?
    
    /// Count of views of the video, in a shortened string.
    ///
    /// Possibly not defined when reading in ``YTPlaylist/frontVideos`` properties.
    public var viewCount: String?
    
    /// String representing the moment when the video was posted.
    ///
    /// Usually like `posted 3 months ago`.
    ///
    /// Possibly not defined when reading in ``YTPlaylist/frontVideos`` properties.
    public var timePosted: String?
    
    /// String representing the duration of the video.
    ///
    /// Can be `live` instead of `ab:cd` if the video is a livestream.
    public var timeLength: String?
    
    /// Array of thumbnails.
    ///
    /// Usually sorted by resolution, from low to high.
    ///
    /// Possibly not defined when reading in ``YTPlaylist/frontVideos`` properties.
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
