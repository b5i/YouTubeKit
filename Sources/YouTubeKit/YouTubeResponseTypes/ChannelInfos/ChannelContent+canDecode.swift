//
//  ChannelContent+canDecode.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension ChannelContent {
    static func canDecode(data: Data) -> Bool {
        return canDecode(json: JSON(data))
    }
}
