//
//  YTComment.swift
//  
//
//  Created by Antoine Bollengier on 02.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

public struct YTComment: Sendable {
    public init(commentIdentifier: String, sender: YTChannel? = nil, text: String, timePosted: String? = nil, translateString: String? = nil, likesCount: String? = nil, likesCountWhenUserLiked: String? = nil, replyLevel: Int? = nil, replies: [YTComment], totalRepliesNumber: String? = nil, actionsParams: [CommentAction : String], likeState: YTLikeStatus? = nil, isLikedByVideoCreator: Bool? = nil) {
        self.commentIdentifier = commentIdentifier
        self.sender = sender
        self.text = text
        self.timePosted = timePosted
        self.translateString = translateString
        self.likesCount = likesCount
        self.likesCountWhenUserLiked = likesCountWhenUserLiked
        self.replyLevel = replyLevel
        self.replies = replies
        self.totalRepliesNumber = totalRepliesNumber
        self.actionsParams = actionsParams
        self.likeState = likeState
        self.isLikedByVideoCreator = isLikedByVideoCreator
    }
    
    public var commentIdentifier: String
    
    public var sender: YTChannel?
    
    public var text: String
    
    public var timePosted: String?
    
    public var translateString: String?
    
    public var likesCount: String?
    
    public var likesCountWhenUserLiked: String?
        
    public var replyLevel: Int?
    
    public var replies: [YTComment] = []
    
    public var totalRepliesNumber: String?
        
    public var actionsParams: [CommentAction: String] = [:]
    
    public var likeState: YTLikeStatus?
    
    public var isLikedByVideoCreator: Bool?
        
    public enum CommentAction: String, Sendable {
        case like, dislike, removeLike, removeDislike
        case reply
        case edit, delete
        case repliesContinuation
        case translate
    }
}
