//
//  DeletePlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//

import Foundation

public struct DeletePlaylistResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .deletePlaylistHeaders
    
    public static var parametersValidationList: ValidationList = [.browseId: .playlistIdWithoutVLPrefixValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the delete action was successful.
    public var success: Bool = false
    
    /// String representing the playlist's id.
    public var playlistId: String?
    
    public static func decodeData(data: Data) -> DeletePlaylistResponse {
        let json = JSON(data)
        var toReturn = DeletePlaylistResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false

        for command in json["command"]["commandExecutorCommand"]["commands"].arrayValue {
            if command["removeFromGuideSectionAction"]["handlerData"].string == "GUIDE_ACTION_REMOVE_FROM_PLAYLISTS" {
                toReturn.success = true
            }
            if let playlistId = command["removeFromGuideSectionAction"]["guideEntryId"].string {
                toReturn.playlistId = playlistId
            }
        }
        return toReturn
    }
}

