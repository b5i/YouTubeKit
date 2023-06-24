//
//  YTLittleChannelInfos.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Structure representing the base informations about a YouTube channel, including its name and ID.
public struct YTLittleChannelInfos: Codable {
    /// Name of the owning channel.
    public var name: String?
    
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
}
