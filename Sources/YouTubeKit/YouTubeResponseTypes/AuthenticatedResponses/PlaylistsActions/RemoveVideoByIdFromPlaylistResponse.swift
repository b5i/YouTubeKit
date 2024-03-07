//
//  RemoveVideoByIdFromPlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct RemoveVideoByIdFromPlaylistResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .removeVideoByIdFromPlaylistHeaders
    
    public static var parametersValidationList: ValidationList = [.movingVideoId: .videoIdValidator, .browseId: .playlistIdWithoutVLPrefixValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the remove action was successful.
    public var success: Bool = false
    
    public static func decodeJSON(json: JSON) -> RemoveVideoByIdFromPlaylistResponse {
        var toReturn = RemoveVideoByIdFromPlaylistResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true), json["status"].string == "STATUS_SUCCEEDED" else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = true
        
        return toReturn
    }
}
