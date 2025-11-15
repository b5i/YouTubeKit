//
//  YTSearchResult+decodeJSON.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 19.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YTSearchResult {
    /// Decode JSON from raw data.
    /// - Parameter data: raw data to be decoded.
    /// - Returns: An instance of the YTSearchResult.
    static func decodeJSON(data: Data) -> Self? {
        return decodeJSON(json: JSON(data))
    }
}
