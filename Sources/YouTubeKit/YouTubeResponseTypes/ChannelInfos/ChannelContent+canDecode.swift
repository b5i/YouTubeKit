//
//  ChannelContent+canDecode.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension ChannelContent {
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use canDecode(json: JSON) instead. You can convert your Data into JSON by calling the JSON(_ data: Data) initializer.") // deprecated as you can't really find some tab JSON in raw data.
    static func canDecode(data: Data) -> Bool {
        return canDecode(json: JSON(data))
    }
}
