//
//  ChannelContent+decodeJSONFromTab.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension ChannelContent {
    static func decodeJSONFromTab(_ tab: Data, channelInfos: YTLittleChannelInfos?) -> Self? {
        return decodeJSONFromTab(JSON(tab), channelInfos: channelInfos)
    }
}
