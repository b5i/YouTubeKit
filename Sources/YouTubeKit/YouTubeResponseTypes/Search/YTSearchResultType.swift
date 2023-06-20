//
//  YTSearchResultType.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 19.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// The string value of the YTSearchResultTypes are the HTML renderer values in YouTube's API response
public enum YTSearchResultType: String, Codable, CaseIterable {
    /// Types represents the string value of their distinguished JSON dictionnary's name.
    case video = "videoRenderer"
    case channel = "channelRenderer"
    case playlist = "playlistRenderer"
    
    /// Get the struct that has to be use to decode a particular item.
    static func getDecodingStruct(forType type: Self) -> (any YTSearchResult.Type) {
        switch type {
        case .video:
            return Video.self
        case .channel:
            return Channel.self
        case .playlist:
            return Playlist.self
        }
    }
    
    /// Struct representing a video.
    public struct Video: YTSearchResult, Codable {
        public static func == (lhs: YTSearchResultType.Video, rhs: YTSearchResultType.Video) -> Bool {
            return lhs.channel.browseId == rhs.channel.browseId && lhs.channel.name == rhs.channel.name && lhs.thumbnails == rhs.thumbnails && lhs.timeLength == rhs.timeLength && lhs.timePosted == rhs.timePosted && lhs.title == rhs.title && lhs.videoId == rhs.videoId && lhs.viewCount == rhs.viewCount
        }
        
        public static func decodeJSON(json: JSON) -> Video {
            /// Inititalize a new ``YTSearchResultType/Video-swift.struct`` instance to put the informations in it.
            var video = Video()
            
            video.videoId = json["videoId"].string
            
            if json["title"]["simpleText"].string != nil {
                video.title = json["title"]["simpleText"].string
            } else {
                video.title = json["title"]["runs"][0]["text"].string
            }
            
            video.channel.name = json["ownerText"]["runs"][0]["text"].string
            video.channel.browseId = json["ownerText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string
            
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
        
        /// String identifier of the video, can be used to get the infos of the video.
        ///
        /// For example:
        /// ```swift
        /// let YTM = YouTubeModel()
        /// let videoId: String = ...
        /// VideoInfosResponse.sendRequest(youtubeModel: YTM, data: [.query : videoId], result: { result, error in
        ///      print(result)
        ///      print(error)
        /// })
        /// ```
        public var videoId: String?
        
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
    
    /// Struct representing a channel.
    public struct Channel: YTSearchResult {
        public static func decodeJSON(json: JSON) -> Channel {
            /// Inititalize a new ``YTSearchResultType/Channel-swift.struct`` instance to put the informations in it.
            var channel = Channel()
            channel.name = json["title"]["simpleText"].string
            
            channel.browseId = json["channelId"].string
            
            YTThumbnail.appendThumbnails(json: json, thumbnailList: &channel.thumbnails)
            
            /// There's an error in YouTube's API
            channel.subscriberCount = json["videoCountText"]["simpleText"].string
            
            if let badgesList = json["ownerBadges"].array {
                for badge in badgesList {
                    if let badgeName = badge["metadataBadgeRenderer"]["style"].string {
                        channel.badges.append(badgeName)
                    }
                }
            }
            
            return channel
        }
        
        public static var type: YTSearchResultType = .channel
        
        public var id: Int?
        
        /// Channel's name.
        public var name: String?
        
        /// Channel's identifier, can be used to get the informations about the channel.
        ///
        /// For example:
        /// ```swift
        /// let YTM = YouTubeModel()
        /// let channelBrowseId: String = ...
        /// ChannelInfosResponse.sendRequest(youtubeModel: YTM, data: [.query : channelBrowseId], result: { result, error in
        ///      print(result)
        ///      print(error)
        /// })
        /// ```
        public var browseId: String?
        
        /// Array of thumbnails representing the avatar of the channel.
        ///
        /// Usually sorted by resolution, from low to high.
        public var thumbnails: [YTThumbnail] = []
        
        /// Channel's subscribers count.
        ///
        /// Usually like "123k subscribers".
        public var subscriberCount: String?
        
        /// Array of string identifiers of the badges that a channel has.
        ///
        /// Usually like "BADGE_STYLE_TYPE_VERIFIED
        public var badges: [String] = []
        
        ///Not necessary here because of prepareJSON() method
        /*
        enum CodingKeys: String, CodingKey {
            case name
            case stringIdentifier
            case thumbnails
            case subscriberCount
            case badges
        }
         */
    }

    /// Struct representing a playlist.
    public struct Playlist: YTSearchResult {
        public static func == (lhs: YTSearchResultType.Playlist, rhs: YTSearchResultType.Playlist) -> Bool {
            return lhs.channel.browseId == rhs.channel.browseId && lhs.channel.name == rhs.channel.name && lhs.playlistId == rhs.playlistId && lhs.timePosted == rhs.timePosted && lhs.videoCount == rhs.videoCount && lhs.title == rhs.title && lhs.frontVideos == rhs.frontVideos
        }
        
        public static func decodeJSON(json: JSON) -> Playlist {
            /// Inititalize a new ``YTSearchResultType/Playlist-swift.struct`` instance to put the informations in it.
            var playlist = Playlist()
            
            playlist.playlistId = json["playlistId"].string
            
            playlist.title = json["title"]["simpleText"].string
            
            YTThumbnail.appendThumbnails(json: json["thumbnailRenderer"]["playlistVideoThumbnailRenderer"], thumbnailList: &playlist.thumbnails)
                        
            playlist.videoCount = ""
            for videoCountTextPart in json["videoCountText"]["runs"].array ?? [] {
                playlist.videoCount! += videoCountTextPart["text"].string ?? ""
            }
            
            playlist.channel.name = ""
            for channelNameTextPart in json["longBylineText"]["runs"].array ?? [] {
                playlist.channel.name! += channelNameTextPart["text"].string ?? ""
            }
            
            playlist.channel.browseId = json["longBylineText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string
            
            playlist.timePosted = json["publishedTimeText"]["simpleText"].string
            
            for frontVideoIndex in 0..<(json["videos"].array?.count ?? 0) {
                playlist.frontVideos.append(
                    Video.decodeJSON(json: json["videos"][frontVideoIndex]["childVideoRenderer"])
                )
            }
            
            return playlist
        }
        
        public static var type: YTSearchResultType = .playlist
        
        public var id: Int?
        
        /// Playlist's identifier, can be used to get the informations about the channel.
        ///
        /// For example:
        /// ```swift
        /// let YTM = YouTubeModel()
        /// let playlistBrowseId: String = ...
        /// PlaylistInfosResponse.sendRequest(youtubeModel: YTM, data: [.query : playlistBrowseId], result: { result, error in
        ///      print(result)
        ///      print(error)
        /// })
        /// ```
        public var playlistId: String?
        
        /// Title of the playlist.
        public var title: String?
        
        /// Array of thumbnails.
        ///
        /// Usually sorted by resolution, from low to high.
        public var thumbnails: [YTThumbnail] = []
        
        /// A string representing the number of video in the playlist.
        public var videoCount: String?

        /// Channel informations.
        public var channel: YTLittleChannelInfos = .init()
        
        /// String representing the moment when the video was posted.
        ///
        /// Usually like `posted 3 months ago`.
        public var timePosted: String?
        
        /// An array of videos that are contained in the playlist, usually the first ones.
        public var frontVideos: [Video] = []
        
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
}
