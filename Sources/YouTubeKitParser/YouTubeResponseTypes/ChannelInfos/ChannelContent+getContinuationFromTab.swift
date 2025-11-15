//
//  ChannelContent+getContinuationFromTab.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 25.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension ChannelContent {
    static func getContinuationFromTab(json: JSON) -> String? {
        guard let videosArray = json["tabRenderer", "content", "richGridRenderer", "contents"].array else { return nil }
        
        /// The token is generally at the end so we reverse it
        for element in videosArray.reversed() {
            if let token = element["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                return token
            }
        }
        return nil
    }
}
