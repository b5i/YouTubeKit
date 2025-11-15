//
//  AddVideoToPlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct AddVideoToPlaylistResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .addVideoToPlaylistHeaders
    
    public static let parametersValidationList: ValidationList = [.browseId: .playlistIdWithoutVLPrefixValidator, .movingVideoId: .videoIdValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the append action was successful.
    public var success: Bool = false
    
    /// String representing the id of the video that has been added to the playlist.
    public var addedVideoId: String?
    
    /// String representing the id in the playlist of the video that has been added to the playlist.
    public var addedVideoIdInPlaylist: String?
    
    /// String representing the playlist's id.
    public var playlistId: String?
    
    /// String representing the account's id.
    public var playlistCreatorId: String?
    
    public static func decodeJSON(json: JSON) -> AddVideoToPlaylistResponse {
        var toReturn = AddVideoToPlaylistResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true), json["status"].string == "STATUS_SUCCEEDED", let playlistModificationResults = json["playlistEditResults"].array else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = true
        
        for playlistModificationResult in playlistModificationResults {
            if playlistModificationResult["playlistEditVideoAddedResultData"].exists() {
                toReturn.addedVideoId = playlistModificationResult["playlistEditVideoAddedResultData", "videoId"].string
                toReturn.addedVideoIdInPlaylist = playlistModificationResult["playlistEditVideoAddedResultData", "setVideoId"].string
                break
            }
        }
        
        (toReturn.playlistId, toReturn.playlistCreatorId) = CreatePlaylistResponse.extractPlaylistAndCreatorIdsFrom(json: json)
            
        return toReturn
    }
}
