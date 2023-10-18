//
//  AllPossibleHostPlaylistsResponse.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public struct AllPossibleHostPlaylistsResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .usersAllPlaylistsHeaders
    
    public var isDisconnected: Bool = true
    
    public var playlistsAndStatus: [(playlist: YTPlaylist, isVideoPresentInside: Bool)] = []

    public static func decodeData(data: Data) -> AllPossibleHostPlaylistsResponse {
        let dataString = String(decoding: data, as: UTF8.self)
        let json = JSON(data)
        var toReturn = AllPossibleHostPlaylistsResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        for content in json["contents"].arrayValue {
            if content["addToPlaylistRenderer"].exists() {
                for playlistJSON in content["addToPlaylistRenderer"]["playlists"].arrayValue {
                    if let playlistId = playlistJSON["playlistAddToOptionRenderer"]["playlistId"].string, let containsVideo = playlistJSON["playlistAddToOptionRenderer"]["containsSelectedVideos"].string {
                        var playlist = YTPlaylist(playlistId: playlistId.hasPrefix("VL") ? playlistId : "VL" + playlistId)
                        playlist.title = playlistJSON["playlistAddToOptionRenderer"]["title"]["simpleText"].string
                        playlist.privacy = YTPrivacy(rawValue: playlistJSON["playlistAddToOptionRenderer"]["privacy"].stringValue)
                        toReturn.playlistsAndStatus.append((playlist, containsVideo == "ALL"))
                    }
                }
            }
        }
        
        return toReturn
    }
}
