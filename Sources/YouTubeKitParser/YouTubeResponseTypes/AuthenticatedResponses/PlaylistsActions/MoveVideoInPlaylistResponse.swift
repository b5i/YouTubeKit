//
//  MoveVideoInPlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct MoveVideoInPlaylistResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .moveVideoInPlaylistHeaders
    
    public static let parametersValidationList: ValidationList = [.movingVideoId: .existenceValidator, .browseId: .playlistIdWithoutVLPrefixValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the append action was successful.
    public var success: Bool = false
    
    /// String representing the playlist's id.
    public var playlistId: String?
    
    public static func decodeJSON(json: JSON) -> MoveVideoInPlaylistResponse {
        var toReturn = MoveVideoInPlaylistResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true), json["status"].string == "STATUS_SUCCEEDED" else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = true
        
        for action in json["actions"].arrayValue {
            let newPlaylistRenderer = action["updatePlaylistAction", "updatedRenderer", "playlistVideoListRenderer"]
            if newPlaylistRenderer.exists() {
                toReturn.playlistId = newPlaylistRenderer["playlistId"].string
                break
            }
        }
        
        return toReturn
    }
}
