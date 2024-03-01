//
//  RemoveLikeFromVideoResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//

import Foundation

public struct RemoveLikeFromVideoResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .removeLikeStatusFromVideoHeaders
    
    public static var parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    public var isDisconnected: Bool = true
    
    public static func decodeData(data: Data) -> RemoveLikeFromVideoResponse {
        let json = JSON(data)
        var toReturn = RemoveLikeFromVideoResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        return toReturn
    }
}
