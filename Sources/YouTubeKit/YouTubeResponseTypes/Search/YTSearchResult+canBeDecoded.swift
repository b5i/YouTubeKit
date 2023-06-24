//
//  YTSearchResult+canBeDecoded.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YTSearchResult {
    /// Method indicating wether some Data can be converted to this type of ``YTSearchResult``.
    /// - Parameter data: the data to be checked.
    /// - Returns: a boolean indicating if the conversion is possible.
    static func canBeDecoded(data: Data) -> Bool {
        return canBeDecoded(json: JSON(data))
    }
}
