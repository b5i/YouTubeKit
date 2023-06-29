//
//  YTLittleChannelInfos.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Structure representing the base informations about a YouTube channel, including its name and ID.
public struct YTLittleChannelInfos: Codable {
    /// Channel's identifier, can be used to get the informations about the channel.
    ///
    /// For example:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let channelId: String = ...
    /// ChannelInfosResponse.sendRequest(youtubeModel: YTM, data: [.browseId : channelId], result: { result, error in
    ///      print(result)
    ///      print(error)
    /// })
    /// ```
    public var channelId: String?
    
    /// Name of the owning channel.
    public var name: String?
    
    /// Array of thumbnails representing the avatar of the channel.
    ///
    /// Usually sorted by resolution from low to high.
    /// Only found in ``YTVideo``items in ``SearchResponse`` and ``HomeScreenResponse`` and their continuation.
    public var thumbnails: [YTThumbnail] = []
}
