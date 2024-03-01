//
//  YTPrivacy.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 27.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Enum representing the various privacy levels of YouTube like videos or playlists.
public enum YTPrivacy: String, Codable, Hashable, CaseIterable {
    case `private` = "PRIVATE"
    case `public` = "PUBLIC"
    case unlisted = "UNLISTED"
}
