//
//  RemoveVideoFromPlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// - Note: For the moment, no extraction of the `playlistEditToken` has been done and you need to pass `"CAFAAQ%3D%3D"` as an argument for it.
public struct RemoveVideoFromPlaylistResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .removeVideoFromPlaylistHeaders
    
    public static let parametersValidationList: ValidationList = [.movingVideoId: .existenceValidator, .playlistEditToken: .existenceValidator, .browseId: .playlistIdWithoutVLPrefixValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the remove action was successful.
    public var success: Bool = false
    
    public static func decodeJSON(json: JSON) -> RemoveVideoFromPlaylistResponse {
        var toReturn = RemoveVideoFromPlaylistResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true), json["status"].string == "STATUS_SUCCEEDED" else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = true

        return toReturn
    }
}
