//
//  YTChannel.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation


/// Struct representing a channel.
public struct YTChannel: YTSearchResult, YouTubeChannel {
    public init(id: Int? = nil, name: String? = nil, channelId: String, handle: String? = nil, thumbnails: [YTThumbnail] = [], subscriberCount: String? = nil, badges: [String] = [], videoCount: String? = nil) {
        self.id = id
        self.name = name
        self.handle = handle
        self.channelId = channelId
        self.thumbnails = thumbnails
        self.subscriberCount = subscriberCount
        self.badges = badges
        self.videoCount = videoCount
    }
    
    public static func canBeDecoded(json: JSON) -> Bool {
        return json["channelId"].string != nil
    }
    
    public static func decodeJSON(json: JSON) -> YTChannel? {
        /// Check if the JSON can be decoded as a Channel.
        guard let channelId = json["channelId"].string else { return nil }

        /// Inititalize a new ``YTSearchResultType/Channel-swift.struct`` instance to put the informations in it.
        var channel = YTChannel(channelId: channelId)
        channel.name = json["title", "simpleText"].string
        if json["navigationEndpoint", "browseEndpoint", "canonicalBaseUrl"].stringValue.contains("/c/") || json["subscriberCountText", "simpleText"].string?.hasPrefix("@") != true { // special channel json with no handle
            channel.subscriberCount = json["subscriberCountText", "simpleText"].string
            channel.videoCount = json["videoCountText", "runs"].array?.map {$0["text"].stringValue}.reduce("", +) ?? json["videoCountText", "simpleText"].string
        } else {
            channel.handle = json["subscriberCountText", "simpleText"].string
            channel.subscriberCount = json["videoCountText", "runs"].array?.map {$0["text"].stringValue}.reduce("", +) ?? json["videoCountText", "simpleText"].string
        }
        YTThumbnail.appendThumbnails(json: json["thumbnail"], thumbnailList: &channel.thumbnails)
                        
        if let badgesList = json["ownerBadges"].array {
            for badge in badgesList {
                if let badgeName = badge["metadataBadgeRenderer", "style"].string {
                    channel.badges.append(badgeName)
                }
            }
        }
        
        return channel
    }
    
    public static let type: YTSearchResultType = .channel
    
    public var id: Int?
    
    /// Channel's name.
    public var name: String?
    
    /// Channel's handle.
    public var handle: String?
    
    /// Channel's identifier, can be used to get the informations about the channel.
    ///
    /// For example:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let channelId: String = ...
    /// ChannelInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.browseId : channelId], result: { result in
    ///      print(result)
    /// })
    /// ```
    public var channelId: String
    
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
    /// Usually like "BADGE_STYLE_TYPE_VERIFIED"
    public var badges: [String] = []
    
    /// String representing the video count of the channel. Might not be present if the channel handle should be displayed instead.
    public var videoCount: String?
    
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
