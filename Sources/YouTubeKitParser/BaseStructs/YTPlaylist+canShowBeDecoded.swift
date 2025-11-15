//
//  YTPlaylist+canShowBeDecoded.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 25.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YTPlaylist {
    /// Indicate if a certain JSON can be decoded as a YouTube "show".
    /// - Parameter json: the JSON should be the **inside** of a dictionnary called "gridShowRenderer" by YouTube's API.
    /// - Returns: a boolean indicating whether it can be decoded as a show or not.
    static func canShowBeDecoded(json: JSON) -> Bool {
        return json["navigationEndpoint", "browseEndpoint", "browseId"].string != nil
    }
}
