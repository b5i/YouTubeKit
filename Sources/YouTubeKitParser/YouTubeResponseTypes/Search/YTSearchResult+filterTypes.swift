//
//  YTSearchResult+filterTypes.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 19.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension [YTSearchResult] {
    /// Making easier to filter item types of your array
    func filterTypes(acceptedTypes: [YTSearchResultType] = YTSearchResultType.allCases) -> [any YTSearchResult] {
        return self.filter({acceptedTypes.contains(type(of: $0).type)})
    }
}
