//
//  ReplyCommentResponse.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

/// Response to reply to a comment of a video.
public struct ReplyCommentResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .replyCommentHeaders
    
    public static let parametersValidationList: ValidationList = [.text: .textSanitizerValidator, .params: .existenceValidator]
    
    public var isDisconnected: Bool = true
    
    public var success: Bool = false
    
    public var newComment: YTComment?

    public static func decodeJSON(json: JSON) throws -> Self {
        let normalCommentDecoding = try CreateCommentResponse.decodeJSON(json: json)
        return Self(isDisconnected: normalCommentDecoding.isDisconnected, success: normalCommentDecoding.success, newComment: normalCommentDecoding.newComment)
    }
}
