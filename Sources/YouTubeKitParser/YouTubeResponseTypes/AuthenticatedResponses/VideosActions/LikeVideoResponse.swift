//
//  LikeVideoResponse.swift
//  
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct LikeVideoResponse: AuthenticatedResponse {
    public static let headersType: HeaderTypes = .likeVideoHeaders
    
    public static let parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    public var isDisconnected: Bool = true
    
    public static func decodeJSON(json: JSON) -> LikeVideoResponse {
        var toReturn = LikeVideoResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        return toReturn
    }
}
