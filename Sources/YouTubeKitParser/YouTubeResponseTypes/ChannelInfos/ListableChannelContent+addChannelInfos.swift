//
//  ListableChannelContent+addChannelInfos.swift
//
//
//  Created by Antoine Bollengier on 11.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension ListableChannelContent {
    mutating func addChannelInfos(_ channelInfos: YTLittleChannelInfos) {
        for (offset, item) in items.enumerated() {
            if var castedItem = (item as? YTVideo), castedItem.channel == nil {
                castedItem.channel = channelInfos
                items[offset] = castedItem
            } else if var castedItem = (item as? YTPlaylist), castedItem.channel == nil {
                castedItem.channel = channelInfos
                items[offset] = castedItem
            }
        }
    }
}
