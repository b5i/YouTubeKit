//
//  CreateCommentResponse.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

/// Response to create a comment on a video.
public struct CreateCommentResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .createCommentHeaders
    
    public static let parametersValidationList: ValidationList = [.params: .existenceValidator, .text: .textSanitizerValidator]
    
    public var isDisconnected: Bool = true
    
    public var success: Bool = false
    
    public var newComment: YTComment?
    
    public static func decodeJSON(json: JSON) throws -> Self {
        var toReturn = Self()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        toReturn.success = json["actionResult", "status"].string == "STATUS_SUCCEEDED"
        
        var modifiedJSONForVideoCommentsResponse = JSON()
        
        modifiedJSONForVideoCommentsResponse["responseContext"] = json["responseContext"]
        
        modifiedJSONForVideoCommentsResponse["frameworkUpdates"] = json["frameworkUpdates"]
        
        guard let createCommentOrReplyActionJSON = json["actions"].arrayValue.first(where: {$0["createCommentAction"].exists()})?["createCommentAction", "contents"].rawString() ?? json["actions"].arrayValue.first(where: {$0["createCommentReplyAction"].exists()})?["createCommentReplyAction", "contents"].rawString() else {
            throw ResponseExtractionError(reponseType: Self.self, stepDescription: "Couldn't extract the creation tokens.")
        }
        
        modifiedJSONForVideoCommentsResponse["onResponseReceivedEndpoints"] = JSON(parseJSON: "[{\"reloadContinuationItemsCommand\": {\"continuationItems\": [\(createCommentOrReplyActionJSON)]}}]")
        
        toReturn.newComment = try VideoCommentsResponse.decodeJSON(json: modifiedJSONForVideoCommentsResponse).results.first
        
        return toReturn
    }
}
