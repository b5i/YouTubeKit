//
//  RemoveVideoByIdFromPlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct RemoveVideoByIdFromPlaylistResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .removeVideoByIdFromPlaylistHeaders
    
    public static let parametersValidationList: ValidationList = [.movingVideoId: .videoIdValidator, .browseId: .playlistIdWithoutVLPrefixValidator]
    
    public var isDisconnected: Bool = true
    
    public var success: Bool = false
    
    public static func decodeJSON(json: JSON) -> RemoveVideoByIdFromPlaylistResponse {
        var toReturn = RemoveVideoByIdFromPlaylistResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true), json["status"].string == "STATUS_SUCCEEDED" else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = true
        
        return toReturn
    }
}
