//
//  LikeVideoResponse.swift
//  
//
//  Created by Antoine Bollengier on 16.10.2023.
//

import Foundation

public struct LikeVideoResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .likeVideoHeaders
    
    public var isDisconnected: Bool = true
    
    public static func decodeData(data: Data) -> LikeVideoResponse {
        let json = JSON(data)
        var toReturn = LikeVideoResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        return toReturn
    }
}
