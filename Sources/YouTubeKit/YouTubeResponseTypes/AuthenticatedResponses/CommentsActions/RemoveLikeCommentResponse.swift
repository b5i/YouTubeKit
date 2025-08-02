//
//  RemoveLikeCommentResponse.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

/// Response remove a like from a video.
public struct RemoveLikeCommentResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .removeLikeCommentHeaders
    
    public static let parametersValidationList: ValidationList = [.params: .existenceValidator]
    
    public var isDisconnected: Bool = true
    
    public var success: Bool = false
    
    public static func decodeJSON(json: JSON) -> Self {
        var toReturn = Self()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        toReturn.success = json["actionResults"].arrayValue.first(where: {$0["status"].string == "STATUS_SUCCEEDED" && $0["feedback"].string == "FEEDBACK_UNLIKE"}) != nil
        
        return toReturn
    }
}
