//
//  CreatePlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct CreatePlaylistResponse: AuthenticatedResponse {
    public static let headersType: HeaderTypes = .createPlaylistHeaders
    
    public static let parametersValidationList: ValidationList = [.query: .existenceValidator, .params: .privacyValidator, .movingVideoId: .videoIdValidator]
    
    public var isDisconnected: Bool = true
    
    /// String representing the new playlist's id.
    public var createdPlaylistId: String?
    
    /// String representing the account's id.
    public var playlistCreatorId: String?
    
    public static func decodeJSON(json: JSON) -> CreatePlaylistResponse {
        var toReturn = CreatePlaylistResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        (toReturn.createdPlaylistId, toReturn.playlistCreatorId) = CreatePlaylistResponse.extractPlaylistAndCreatorIdsFrom(json: json)
        
        return toReturn
    }
    
    /// Extracts from a JSON response (generally a playlist modification response) the playlistId and the playlist's creator's id.
    public static func extractPlaylistAndCreatorIdsFrom(json: JSON) -> (playlistId: String?, creatorId: String?) {
        var toReturn: (playlistId: String?, creatorId: String?) = (nil, nil)
        for action in json["actions"].arrayValue {
            if let results = action["runAttestationCommand", "ids"].array {
                for result in results {
                    if let playlistId = result["playlistId"].string {
                        toReturn.playlistId = "VL" + playlistId
                    } else if let playlistCreatorId = result["externalChannelId"].string {
                        toReturn.creatorId = playlistCreatorId
                    }
                }
            }
        }
        return toReturn
    }
}
