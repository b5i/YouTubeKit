//
//  RemoveVideoByIdFromPlaylistResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//

import Foundation

public struct RemoveVideoByIdFromPlaylistResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .removeVideoByIdFromPlaylistHeaders
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the remove action was successful.
    public var success: Bool = false
    
    public static func decodeData(data: Data) -> RemoveVideoByIdFromPlaylistResponse {
        let json = JSON(data)
        var toReturn = RemoveVideoByIdFromPlaylistResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true), json["status"].string == "STATUS_SUCCEEDED" else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = true
        
        return toReturn
    }
}
