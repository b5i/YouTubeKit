//
//  DeletePlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct DeletePlaylistResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .deletePlaylistHeaders
    
    public static let parametersValidationList: ValidationList = [.browseId: .playlistIdWithoutVLPrefixValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the delete action was successful.
    public var success: Bool = false
    
    /// String representing the playlist's id.
    public var playlistId: String?
    
    public static func decodeJSON(json: JSON) -> DeletePlaylistResponse {
        var toReturn = DeletePlaylistResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false

        for command in json["command", "commandExecutorCommand", "commands"].arrayValue {
            if command["removeFromGuideSectionAction", "handlerData"].string == "GUIDE_ACTION_REMOVE_FROM_PLAYLISTS" {
                toReturn.success = true
            }
            if let playlistId = command["removeFromGuideSectionAction", "guideEntryId"].string {
                toReturn.playlistId = playlistId
            }
        }
        return toReturn
    }
}

