//
//  ListableChannelContent.swift
//
//
//  Created by Antoine Bollengier on 15.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Protocol to group ChannelContent structures that have a list of items where their types are some YTSearchResult.
public protocol ListableChannelContent: ChannelContent {
    /// Array listing the YTSearchResult types present in ``ListableChannelContent/items``.
    static var itemsTypes: [any YTSearchResult.Type] { get }
    
    /// Items contained in channel's tab. Contains only results of types 
    var items: [any YTSearchResult] { get set }
    
    /// A function that will add their channel's information to every item in ``items`` (if not already present). The default implementation will do that for items that are of type ``YTVideo`` or ``YTPlaylist``.
    mutating func addChannelInfos(_ channelInfos: YTLittleChannelInfos)
}
