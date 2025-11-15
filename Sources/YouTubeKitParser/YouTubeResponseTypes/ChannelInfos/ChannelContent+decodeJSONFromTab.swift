//
//  ChannelContent+decodeJSONFromTab.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension ChannelContent {
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use decodeJSONFromTab(_ json: JSON, channelInfos: YTLittleChannelInfos?) instead. You can convert your Data into JSON by calling the JSON(_ data: Data) initializer.") // deprecated as you can't really find some tab JSON in raw data.
    static func decodeJSONFromTab(_ tab: Data, channelInfos: YTLittleChannelInfos?) -> Self? {
        return decodeJSONFromTab(JSON(tab), channelInfos: channelInfos)
    }
}
