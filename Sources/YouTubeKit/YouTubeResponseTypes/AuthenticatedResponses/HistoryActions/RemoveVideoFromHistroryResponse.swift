//
//  RemoveVideoFromHistroryResponse.swift
//
//
//  Created by Antoine Bollengier on 03.01.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct RemoveVideoFromHistroryResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .deleteVideoFromHistory
    
    public static let parametersValidationList: ValidationList = [.movingVideoId: .existenceValidator]
    
    public var isDisconnected: Bool = true
    
    /// Success of the deletion operation.
    public var success: Bool = false
        
    public static func decodeJSON(json: JSON) -> RemoveVideoFromHistroryResponse {
        var toReturn = RemoveVideoFromHistroryResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        toReturn.success = json["feedbackResponses", 0, "isProcessed"].bool == true
        
        return toReturn
    }
}
