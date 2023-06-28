//
//  YTPlaylist.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 24.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a playlist.
public struct YTPlaylist: YTSearchResult {
    public static func == (lhs: YTPlaylist, rhs: YTPlaylist) -> Bool {
        return lhs.channel.channelId == rhs.channel.channelId && lhs.channel.name == rhs.channel.name && lhs.playlistId == rhs.playlistId && lhs.timePosted == rhs.timePosted && lhs.videoCount == rhs.videoCount && lhs.title == rhs.title && lhs.frontVideos == rhs.frontVideos
    }
    
    public static func canBeDecoded(json: JSON) -> Bool {
        return json["playlistId"].string != nil
    }
    
    public static func decodeJSON(json: JSON) -> YTPlaylist? {
        /// Check if the JSON can be decoded as a Playlist.
        guard let playlistId = json["playlistId"].string else { return nil }
        /// Inititalize a new ``YTSearchResultType/Playlist-swift.struct`` instance to put the informations in it.
        var playlist = YTPlaylist(playlistId: playlistId.prefix(2) == "VL" ? playlistId : "VL" + playlistId)
                    
        if let playlistTitle = json["title"]["simpleText"].string {
            playlist.title = playlistTitle
        } else {
            var playlistTitle: String = ""
            for playlistTitleTextPart in json["title"]["runs"].array ?? [] {
                playlistTitle += playlistTitleTextPart["text"].string ?? ""
            }
            playlist.title = playlistTitle
        }
        
        YTThumbnail.appendThumbnails(json: json["thumbnailRenderer"]["playlistVideoThumbnailRenderer"], thumbnailList: &playlist.thumbnails)
                    
        playlist.videoCount = ""
        for videoCountTextPart in json["videoCountText"]["runs"].array ?? [] {
            playlist.videoCount! += videoCountTextPart["text"].string ?? ""
        }
        
        playlist.channel.name = ""
        for channelNameTextPart in json["longBylineText"]["runs"].array ?? [] {
            playlist.channel.name! += channelNameTextPart["text"].string ?? ""
        }
        
        playlist.channel.channelId = json["longBylineText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string
        
        playlist.timePosted = json["publishedTimeText"]["simpleText"].string
        
        for frontVideoIndex in 0..<(json["videos"].array?.count ?? 0) {
            let video = json["videos"][frontVideoIndex]["childVideoRenderer"]
            guard YTVideo.canBeDecoded(json: video), let castedVideo = YTVideo.decodeJSON(json: video) else { continue }
            playlist.frontVideos.append(castedVideo)
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
    /// let playlistId: String = ...
    /// PlaylistInfosResponse.sendRequest(youtubeModel: YTM, data: [.query : playlistId], result: { result, error in
    ///      print(result)
    ///      print(error)
    /// })
    /// ```
    public var playlistId: String
    
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
    public var frontVideos: [YTVideo] = []
    
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
