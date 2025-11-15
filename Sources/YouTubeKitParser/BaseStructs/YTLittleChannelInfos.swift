//
//  YTLittleChannelInfos.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Structure representing the base informations about a YouTube channel, including its name and ID. Basic implementation of the ``YouTubeChannel`` protocol.
public struct YTLittleChannelInfos: Codable, YouTubeChannel, Hashable, Sendable {    
    public init(channelId: String, name: String? = nil, thumbnails: [YTThumbnail] = []) {
        self.channelId = channelId
        self.name = name
        self.thumbnails = thumbnails
    }
    
    public var channelId: String
    
    public var name: String?
    
    public var thumbnails: [YTThumbnail] = []
}
