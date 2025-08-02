//
//  AllPossibleHostPlaylistsResponse.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct AllPossibleHostPlaylistsResponse: AuthenticatedResponse {
    public static let headersType: HeaderTypes = .usersAllPlaylistsHeaders
    
    public static let parametersValidationList: ValidationList = [.browseId: .videoIdValidator]
    
    public var isDisconnected: Bool = true
    
    public var playlistsAndStatus: [(playlist: YTPlaylist, isVideoPresentInside: Bool)] = []

    public static func decodeJSON(json: JSON) -> AllPossibleHostPlaylistsResponse {
        var toReturn = AllPossibleHostPlaylistsResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        for content in json["contents"].arrayValue {
            if content["addToPlaylistRenderer"].exists() {
                for playlistJSON in content["addToPlaylistRenderer", "playlists"].arrayValue {
                    if let playlistId = playlistJSON["playlistAddToOptionRenderer", "playlistId"].string, let containsVideo = playlistJSON["playlistAddToOptionRenderer", "containsSelectedVideos"].string {
                        
                        // 2 ways of creating a playlist, YouTube changed (temporarily?) the system by removing the VL prefix at the beginning of the playlist's id.
                        //var playlist = YTPlaylist(playlistId: playlistId.hasPrefix("VL") ? playlistId : "VL" + playlistId)
                        var playlist = YTPlaylist(playlistId: playlistId.hasPrefix("VL") ? String(playlistId.dropFirst(2)) : playlistId)
                        
                        
                        playlist.title = playlistJSON["playlistAddToOptionRenderer", "title", "simpleText"].string
                        playlist.privacy = YTPrivacy(rawValue: playlistJSON["playlistAddToOptionRenderer", "privacy"].stringValue)
                        toReturn.playlistsAndStatus.append((playlist, containsVideo == "ALL"))
                    }
                }
            }
        }
        
        return toReturn
    }
}
