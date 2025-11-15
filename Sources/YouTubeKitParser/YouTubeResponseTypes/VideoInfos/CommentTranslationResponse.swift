//
//  CommentTranslationResponse.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

public struct CommentTranslationResponse: YouTubeResponse {
    public static let headersType: HeaderTypes = .translateCommentHeaders
    
    public static let parametersValidationList: ValidationList = [.params: .existenceValidator]
    
    public var translation: String
    
    public static func decodeJSON(json: JSON) throws -> Self {
        guard json["actionResults"].arrayValue.first(where: {$0["status"].string == "STATUS_SUCCEEDED"}) != nil else {
            throw ResponseExtractionError(reponseType: Self.self, stepDescription: "Request result is not successful.")
        }
        
        guard let translatedText = json["frameworkUpdates", "entityBatchUpdate", "mutations"].arrayValue.first(where: {$0["payload", "commentEntityPayload", "translatedContent", "content"].string != nil })?["payload", "commentEntityPayload", "translatedContent", "content"].string else {
            throw ResponseExtractionError(reponseType: Self.self, stepDescription: "Couldn't extract translted comment.")
        }
        
        return Self(translation: translatedText)
    }
}
