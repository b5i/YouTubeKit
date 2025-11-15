//
//  DeleteCommentResponse.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

/// Response to delete a comment on from video.
public struct DeleteCommentResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .removeCommentHeaders
    
    public static let parametersValidationList: ValidationList = [.params: .existenceValidator]
    
    public var isDisconnected: Bool = true
    
    public var success: Bool = false
    
    public static func decodeJSON(json: JSON) -> Self {
        var toReturn = Self()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        toReturn.success = json["actions"].arrayValue.first(where: {$0["removeCommentAction", "actionResult", "status"].string == "STATUS_SUCCEEDED" && $0["removeCommentAction", "actionResult", "feedback"].string == "FEEDBACK_REMOVE"}) != nil
        
        return toReturn
    }
}
