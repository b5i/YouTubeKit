//
//  YTSearchResultType.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 19.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// The string value of the YTSearchResultTypes are the HTML renderer values in YouTube's API response
public enum YTSearchResultType: String, Codable, CaseIterable, Hashable, Sendable {
    /// Types represents the string value of their distinguished JSON dictionnary's name.
    case video = "videoRenderer"
    case channel = "channelRenderer"
    case playlist = "playlistRenderer"
    
    /// Get the struct that has to be use to decode a particular item.
    static func getDecodingStruct(forType type: Self) -> (any YTSearchResult.Type) {
        switch type {
        case .video:
            return YTVideo.self
        case .channel:
            return YTChannel.self
        case .playlist:
            return YTPlaylist.self
        }
    }
}
