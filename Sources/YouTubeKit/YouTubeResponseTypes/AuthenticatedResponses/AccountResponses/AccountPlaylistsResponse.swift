//
//  AccountPlaylistsResponse.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 27.11.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation

/// Response containing all the playlists of a user.
public struct AccountPlaylistsResponse: AuthenticatedResponse {
    public static let headersType: HeaderTypes = .usersPlaylistsHeaders
    
    public static let parametersValidationList: ValidationList = [:]
    
    public var isDisconnected: Bool = true
    
    public var results: [YTPlaylist] = []
        
    public static func decodeJSON(json: JSON) -> AccountPlaylistsResponse {
        var toReturn = AccountPlaylistsResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        for tab in json["contents", "twoColumnBrowseResultsRenderer", "tabs"].arrayValue {
            guard tab["tabRenderer", "selected"].bool == true else { continue }
            
            for playlistJSON in tab["tabRenderer", "content", "richGridRenderer", "contents"].arrayValue {
                if let playlist = YTPlaylist.decodeLockupJSON(json: playlistJSON["richItemRenderer", "content", "lockupViewModel"]) {
                    toReturn.results.append(playlist)
                }
            }
        }
        
        return toReturn
    }
}

