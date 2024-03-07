//
//  ListableChannelContent.swift
//
//
//  Created by Antoine Bollengier on 15.10.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Protocol to group ChannelContent structures that have a list of items where their types are some YTSearchResult.
public protocol ListableChannelContent: ChannelContent {
    
    /// Items contained in channel's tab. Contains only results of types 
    var items: [any YTSearchResult] { get set }
    
    /// Array listing the YTSearchResult types present in ``ListableChannelContent/items``.
    var itemsTypes: [any YTSearchResult.Type] { get }
}
