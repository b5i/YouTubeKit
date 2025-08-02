//
//  [URLQueryItem]+makeUnique.swift
//
//
//  Created by Antoine Bollengier on 28.08.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

extension [URLQueryItem] {
    /// Remove headers that have the same name but keep the first item with that name.
    func makeUnique() -> [URLQueryItem] {
        var uniqueItems: [URLQueryItem] = []
        for item in self {
            guard !uniqueItems.contains(item) else { continue }
            uniqueItems.append(item)
        }
        return uniqueItems
    }
}
