//
//  YTPlaylist.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 24.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a playlist.
public struct YTPlaylist: YTSearchResult, Sendable {
    public init(id: Int? = nil, playlistId: String, title: String? = nil, thumbnails: [YTThumbnail] = [], videoCount: String? = nil, channel: YTLittleChannelInfos? = nil, timePosted: String? = nil, frontVideos: [YTVideo] = [], privacy: YTPrivacy? = nil) {
        self.id = id
        self.playlistId = playlistId
        self.title = title
        self.thumbnails = thumbnails
        self.videoCount = videoCount
        self.channel = channel
        self.timePosted = timePosted
        self.frontVideos = frontVideos
        self.privacy = privacy
    }
    
    public static func == (lhs: YTPlaylist, rhs: YTPlaylist) -> Bool {
        return lhs.channel?.channelId == rhs.channel?.channelId && lhs.channel?.name == rhs.channel?.name && lhs.playlistId == rhs.playlistId && lhs.timePosted == rhs.timePosted && lhs.videoCount == rhs.videoCount && lhs.title == rhs.title && lhs.frontVideos == rhs.frontVideos
    }
    
    public static func canBeDecoded(json: JSON) -> Bool {
        return json["playlistId"].string != nil
    }
    
    public static func decodeJSON(json: JSON) -> YTPlaylist? {
        /// Check if the JSON can be decoded as a Playlist.
        guard let playlistId = json["playlistId"].string else { return nil }
        /// Inititalize a new ``YTSearchResultType/Playlist-swift.struct`` instance to put the informations in it.
        var playlist = YTPlaylist(playlistId: playlistId.hasPrefix("VL") ? playlistId : "VL" + playlistId)
                    
        if let playlistTitle = json["title", "simpleText"].string {
            playlist.title = playlistTitle
        } else {
            let playlistTitle = json["title", "runs"].arrayValue.map({$0["text"].stringValue}).joined()
            playlist.title = playlistTitle
        }
        
        YTThumbnail.appendThumbnails(json: json["thumbnailRenderer", "playlistVideoThumbnailRenderer", "thumbnail"], thumbnailList: &playlist.thumbnails)
                    
        playlist.videoCount = json["videoCountText", "runs"].arrayValue.map({$0["text"].stringValue}).joined()
        
        if let channelId = json["longBylineText", "runs", 0, "navigationEndpoint", "browseEndpoint", "browseId"].string {
            playlist.channel = YTLittleChannelInfos(channelId: channelId, name: json["longBylineText", "runs"].arrayValue.map({$0["text"].stringValue}).joined())
        }
        
        playlist.timePosted = json["publishedTimeText", "simpleText"].string
        
        for frontVideoIndex in 0..<(json["videos"].array?.count ?? 0) {
            let video = json["videos", frontVideoIndex, "childVideoRenderer"]
            guard YTVideo.canBeDecoded(json: video), let castedVideo = YTVideo.decodeJSON(json: video) else { continue }
            playlist.frontVideos.append(castedVideo)
        }
        
        return playlist
    }
    
    public static func decodeLockupJSON(json: JSON) -> YTPlaylist? {
        guard let playlistId = json["contentId"].string, json["contentType"] == "LOCKUP_CONTENT_TYPE_PLAYLIST" else { return nil }
        
        var playlist = YTPlaylist(playlistId: playlistId.hasPrefix("VL") ? playlistId : "VL" + playlistId)
        
        playlist.title = json["metadata", "lockupMetadataViewModel", "title", "content"].string
        
        let channelElement1 = json["metadata", "lockupMetadataViewModel", "metadata", "contentMetadataViewModel", "metadataRows"]
            .arrayValue.compactMap { metadataPart in
                metadataPart["metadataParts"].array
            }
        
        let channelElement2 = channelElement1
            .first(where: { metadataPart in
                metadataPart.first(where: {
                    $0["text", "commandRuns"]
                        .arrayValue
                        .first?["onTap", "innertubeCommand", "commandMetadata", "webCommandMetadata", "webPageType"]
                        .string == "WEB_PAGE_TYPE_CHANNEL"
                }) != nil
            })
            
        if let channelElement = channelElement2?.first(where: {
                $0["text", "commandRuns"]
                    .arrayValue
                    .first?["onTap", "innertubeCommand", "commandMetadata", "webCommandMetadata", "webPageType"]
                    .string == "WEB_PAGE_TYPE_CHANNEL"
            })?["text"],
            let channelId = channelElement["commandRuns"]
            .array?
            .first?["onTap", "innertubeCommand", "browseEndpoint", "browseId"].string
        {
            playlist.channel = YTLittleChannelInfos(channelId: channelId, name: channelElement["content"].string)
        }
            
        YTThumbnail.appendThumbnails(json: json["contentImage", "collectionThumbnailViewModel", "primaryThumbnail", "thumbnailViewModel"], thumbnailList: &playlist.thumbnails)
        
        mainLoop: for thumbnailOverlay in json["contentImage", "collectionThumbnailViewModel", "primaryThumbnail", "thumbnailViewModel", "overlays"].arrayValue {
            for thumbnailBadge in thumbnailOverlay["thumbnailOverlayBadgeViewModel", "thumbnailBadges"].arrayValue {
                if thumbnailBadge["thumbnailBadgeViewModel", "icon", "sources", 0, "clientResource", "imageName"].string == "PLAYLISTS", let text = thumbnailBadge["thumbnailBadgeViewModel", "text"].string {
                    playlist.videoCount = text
                    break mainLoop
                }
            }
        }
        
        return playlist
    }
    
    public static let type: YTSearchResultType = .playlist
    
    public var id: Int?
    
    /// Playlist's identifier, can be used to get the informations about the channel.
    ///
    /// For example:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let playlistId: String = ...
    /// PlaylistInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.query : playlistId], result: { result in
    ///      print(result)
    /// })
    /// ```
    public var playlistId: String
    
    /// Title of the playlist.
    public var title: String?
    
    /// Array of thumbnails.
    ///
    /// Usually sorted by resolution, from low to high.
    public var thumbnails: [YTThumbnail] = []
    
    /// A string representing the count of video in the playlist.
    public var videoCount: String?

    /// Channel informations.
    public var channel: YTLittleChannelInfos? = nil
    
    /// String representing the moment when the video was posted.
    ///
    /// Usually like `posted 3 months ago`.
    public var timePosted: String?
    
    /// An array of videos that are contained in the playlist, usually the first ones.
    public var frontVideos: [YTVideo] = []
    
    public var privacy: YTPrivacy?
    
    ///Not necessary here because of prepareJSON() method
    /*
    enum CodingKeys: String, CodingKey {
        case playlistId
        case title
        case thumbnails
        case thumbnails
        case videoCount
        case channel
        case timePosted
        case frontVideos
    }
     */
}
