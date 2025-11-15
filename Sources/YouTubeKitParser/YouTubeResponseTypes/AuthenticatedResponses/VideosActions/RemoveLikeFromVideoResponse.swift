//
//  RemoveLikeFromVideoResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct RemoveLikeFromVideoResponse: AuthenticatedResponse {
    public static let headersType: HeaderTypes = .removeLikeStatusFromVideoHeaders
    
    public static let parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    public var isDisconnected: Bool = true
    
    public static func decodeJSON(json: JSON) -> RemoveLikeFromVideoResponse {
        var toReturn = RemoveLikeFromVideoResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        return toReturn
    }
}
