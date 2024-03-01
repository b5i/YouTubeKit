//
//  RemoveVideoFromPlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//

import Foundation

public struct RemoveVideoFromPlaylistResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .removeVideoFromPlaylistHeaders
    
    public static var parametersValidationList: ValidationList = [.movingVideoId: .existenceValidator, .playlistEditToken: .existenceValidator, .browseId: .playlistIdWithoutVLPrefixValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the remove action was successful.
    public var success: Bool = false
    
    public static func decodeData(data: Data) -> RemoveVideoFromPlaylistResponse {
        let json = JSON(data)
        var toReturn = RemoveVideoFromPlaylistResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true), json["status"].string == "STATUS_SUCCEEDED" else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = true

        return toReturn
    }
}
