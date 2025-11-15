//
//  EditReplyCommandResponse.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

/// Response to edit a reply on a comment of a video.
public struct EditReplyCommandResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .editReplyCommentHeaders
    
    public static let parametersValidationList: ValidationList = [.text: .textSanitizerValidator, .params: .existenceValidator]
    
    public var isDisconnected: Bool = true
    
    public var success: Bool = false
    
    public static func decodeJSON(json: JSON) -> Self {
        var toReturn = Self()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        toReturn.success = json["actions"].arrayValue.first(where: {$0["updateCommentReplyAction", "actionResult", "status"].string == "STATUS_SUCCEEDED"}) != nil
        
        return toReturn
    }
}
