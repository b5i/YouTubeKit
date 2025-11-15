//
//  YTSearchResult+canBeDecoded.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YTSearchResult {
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use canBeDecoded(json: JSON) instead. You can convert your Data into JSON by calling the JSON(_ data: Data) initializer.") // deprecated as you can't really find some result JSON in raw data.
    /// Method indicating whether some Data can be converted to this type of ``YTSearchResult``.
    /// - Parameter data: the data to be checked.
    /// - Returns: a boolean indicating if the conversion is possible.
    static func canBeDecoded(data: Data) -> Bool {
        return canBeDecoded(json: JSON(data))
    }
}
