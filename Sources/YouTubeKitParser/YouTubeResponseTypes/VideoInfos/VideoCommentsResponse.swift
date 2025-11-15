//
//  VideoCommentsResponse.swift
//  
//
//  Created by Antoine Bollengier on 02.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

/// A response to get the latest video from channels the YouTubeModel's account is subscribed to.
public struct VideoCommentsResponse: ContinuableResponse {
    public static let headersType: HeaderTypes = .videoCommentsHeaders
    
    public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
    public var results: [YTComment] = []
    
    public var continuationToken: String? = nil
    
    public var visitorData: String? = nil // will never be filled
    
    /// Every sorting mode contains a ``VideoCommentsResponse/SortingMode/token`` that can be used as the continuation of a new ``VideoCommentsResponse``.
    public var sortingModes: [SortingMode] = []
    
    public var commentCreationToken: String? = nil
    
    public static func decodeJSON(json: JSON) throws -> VideoCommentsResponse {
        var toReturn = VideoCommentsResponse()

        let isConnected: Bool = !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true)
                
        var commentRenderers: [CommentRendererTokens] = []
        
        for continuationActions in json["onResponseReceivedEndpoints"].arrayValue {
            for commentRenderer in continuationActions["reloadContinuationItemsCommand", "continuationItems"].array ?? continuationActions["appendContinuationItemsAction", "continuationItems"].arrayValue {
                                
                let commentViewModel: JSON
                let loadRepliesContinuationToken: String?
                
                if commentRenderer["commentThreadRenderer"].exists() {
                    commentViewModel = commentRenderer["commentThreadRenderer", "commentViewModel", "commentViewModel"]
                    loadRepliesContinuationToken = commentRenderer["commentThreadRenderer", "replies", "commentRepliesRenderer", "contents"].arrayValue.first(where: {$0["continuationItemRenderer"].exists()})?["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string
                } else if commentRenderer["commentViewModel"].exists() {
                    commentViewModel = commentRenderer["commentViewModel"]
                    loadRepliesContinuationToken = nil
                } else if commentRenderer["continuationItemRenderer"].exists() {
                    toReturn.continuationToken = commentRenderer["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string ?? commentRenderer["continuationItemRenderer", "button", "buttonRenderer", "command", "continuationCommand", "token"].string
                    
                    continue
                } else if commentRenderer["commentsHeaderRenderer"].exists() {
                    toReturn.commentCreationToken = commentRenderer["commentsHeaderRenderer", "createRenderer", "commentSimpleboxRenderer", "submitButton", "buttonRenderer", "serviceEndpoint", "createCommentEndpoint", "createCommentParams"].string
                    for sortingModes in commentRenderer["commentsHeaderRenderer", "sortMenu", "sortFilterSubMenuRenderer", "subMenuItems"].arrayValue {
                        guard let label = sortingModes["title"].string, let isSelected = sortingModes["selected"].bool, let token = sortingModes["serviceEndpoint", "continuationCommand", "token"].string else { continue }
                        toReturn.sortingModes.append(.init(label: label, isSelected: isSelected, token: token))
                    }
                    continue
                } else {
                    continue
                }
                
                guard let commentRendererTokens = self.extractCommentRendererTokensFromCommentViewModel(commentViewModel, loadRepliesContinuationToken: loadRepliesContinuationToken) else { continue }
            
                commentRenderers.append(commentRendererTokens)
            }
        }
        
        let commentEntities = json["frameworkUpdates", "entityBatchUpdate", "mutations"].arrayValue
        
        for commentRenderer in commentRenderers {
            guard let commentInfoJSONIndex = commentEntities.firstIndex(where: {$0["entityKey"].string == commentRenderer.commentInfo}) else { continue }
            
            let commentInfoJSON = commentEntities[commentInfoJSONIndex]
            
            guard let commentText = commentInfoJSON["payload", "commentEntityPayload", "properties", "content", "content"].string else { continue }
            
            var commentToReturn = YTComment(commentIdentifier: commentRenderer.commentId, text: commentText, replies: [], actionsParams: [:])
            
            commentToReturn.timePosted = commentInfoJSON["payload", "commentEntityPayload", "properties", "publishedTime"].string
            
            commentToReturn.replyLevel = commentInfoJSON["payload", "commentEntityPayload", "properties", "replyLevel"].int
            
            if let senderChannelId = commentInfoJSON["payload", "commentEntityPayload", "author", "channelId"].string {
                commentToReturn.sender = YTChannel(
                    name: commentInfoJSON["payload", "commentEntityPayload", "author", "displayName"].string,
                    channelId: senderChannelId,
                    handle: commentInfoJSON["payload", "commentEntityPayload", "author", "channelCommand", "innertubeCommand", "browseEndpoint", "canonicalBaseUrl"].string?.ytkFirstGroupMatch(for: #"(@[A-Za-z0-9_\.-]+)"#),
                    thumbnails: YTThumbnail.getThumbnails(json: commentInfoJSON["payload", "commentEntityPayload", "avatar", "image"])
                )
            }
            
            if let translateToken = commentInfoJSON["payload", "commentEntityPayload", "translateData", "translateComment", "innertubeCommand", "performCommentActionEndpoint", "action"].string {
                commentToReturn.actionsParams[.translate] = translateToken
                commentToReturn.translateString = commentInfoJSON["payload", "commentEntityPayload", "translateData", "text"].string
            }
            
            commentToReturn.likesCount = commentInfoJSON["payload", "commentEntityPayload", "toolbar", "likeCountNotliked"].string
            commentToReturn.likesCountWhenUserLiked = commentInfoJSON["payload", "commentEntityPayload", "toolbar", "likeCountLiked"].string
            commentToReturn.totalRepliesNumber = commentInfoJSON["payload", "commentEntityPayload", "toolbar", "replyCount"].string
           
            if isConnected, let commentCommands = commentRenderer.commentCommands, let commandsJSON = commentEntities.first(where: {$0["entityKey"].string == commentCommands}) {
                let commandsCluster = commandsJSON["payload", "engagementToolbarSurfaceEntityPayload"]
                if let likeCommandToken = commandsCluster["likeCommand", "innertubeCommand", "performCommentActionEndpoint", "action"].string {
                    commentToReturn.actionsParams[.like] = likeCommandToken
                }
                if let removeLikeCommandToken = commandsCluster["unlikeCommand", "innertubeCommand", "performCommentActionEndpoint", "action"].string {
                    commentToReturn.actionsParams[.removeLike] = removeLikeCommandToken
                }
                if let dislikeCommandToken = commandsCluster["dislikeCommand", "innertubeCommand", "performCommentActionEndpoint", "action"].string {
                    commentToReturn.actionsParams[.dislike] = dislikeCommandToken
                }
                if let removeDislikeCommandToken = commandsCluster["undislikeCommand", "innertubeCommand", "performCommentActionEndpoint", "action"].string {
                    commentToReturn.actionsParams[.removeDislike] = removeDislikeCommandToken
                }
                if let replyCommandToken = commandsCluster["replyCommand", "innertubeCommand", "createCommentReplyDialogEndpoint", "dialog", "commentReplyDialogRenderer", "replyButton", "buttonRenderer", "serviceEndpoint", "createCommentReplyEndpoint", "createReplyParams"].string {
                    commentToReturn.actionsParams[.reply] = replyCommandToken
                }
                if let editButtonToken = commandsCluster["menuCommand", "innertubeCommand", "menuEndpoint", "menu", "menuRenderer", "items"].arrayValue.first(where: {$0["menuNavigationItemRenderer", "navigationEndpoint", "updateCommentDialogEndpoint", "dialog", "commentDialogRenderer", "submitButton", "buttonRenderer", "serviceEndpoint", "commandMetadata", "webCommandMetadata", "apiUrl"].string == "/youtubei/v1/comment/update_comment"})?["menuNavigationItemRenderer", "navigationEndpoint", "updateCommentDialogEndpoint", "dialog", "commentDialogRenderer", "submitButton", "buttonRenderer", "serviceEndpoint", "updateCommentEndpoint", "updateCommentParams"].string {
                    commentToReturn.actionsParams[.edit] = editButtonToken
                } else if let editButtonToken = commandsCluster["menuCommand", "innertubeCommand", "menuEndpoint", "menu", "menuRenderer", "items"].arrayValue.first(where: {$0["menuNavigationItemRenderer", "navigationEndpoint", "updateCommentReplyDialogEndpoint", "dialog", "commentReplyDialogRenderer", "replyButton", "buttonRenderer", "serviceEndpoint", "commandMetadata", "webCommandMetadata", "apiUrl"].string == "/youtubei/v1/comment/update_comment_reply"})?["menuNavigationItemRenderer", "navigationEndpoint", "updateCommentReplyDialogEndpoint", "dialog", "commentReplyDialogRenderer", "replyButton", "buttonRenderer", "serviceEndpoint", "updateCommentReplyEndpoint", "updateReplyParams"].string {
                    commentToReturn.actionsParams[.edit] = editButtonToken
                }
                if let deleteButtonToken = commandsCluster["menuCommand", "innertubeCommand", "menuEndpoint", "menu", "menuRenderer", "items"].arrayValue.first(where: {$0["menuNavigationItemRenderer", "navigationEndpoint", "confirmDialogEndpoint", "content", "confirmDialogRenderer", "confirmButton", "buttonRenderer", "serviceEndpoint", "commandMetadata", "webCommandMetadata", "apiUrl"].string == "/youtubei/v1/comment/perform_comment_action"})?["menuNavigationItemRenderer", "navigationEndpoint", "confirmDialogEndpoint", "content", "confirmDialogRenderer", "confirmButton", "buttonRenderer", "serviceEndpoint", "performCommentActionEndpoint", "action"].string {
                    commentToReturn.actionsParams[.delete] = deleteButtonToken
                }
            }
            
            if let commentAuthData = commentRenderer.commentAuthData, let commentAuthDataJSON = commentEntities.first(where: {$0["entityKey"].string == commentAuthData}) {
                commentToReturn.likeState = self.getLikeStatus(forKey: commentAuthDataJSON["payload", "engagementToolbarStateEntityPayload", "likeState"].stringValue)
                commentToReturn.isLikedByVideoCreator = self.getHeartedByCreatorState(forKey: commentAuthDataJSON["payload", "engagementToolbarStateEntityPayload", "heartState"].stringValue)
            }
            
            if let loadRepliesContinuationToken = commentRenderer.loadRepliesContinuationToken {
                commentToReturn.actionsParams[.repliesContinuation] = loadRepliesContinuationToken
            }
            
            toReturn.results.append(commentToReturn)
        }

        return toReturn
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: ResponseContinuation {
        public static let headersType: HeaderTypes = .videoCommentsContinuationHeaders
        
        public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator]
                
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of videos.
        public var results: [YTComment] = []
        
        public static func decodeJSON(json: JSON) throws -> VideoCommentsResponse.Continuation {
            let extractedResult = try VideoCommentsResponse.decodeJSON(json: json)
            
            return Continuation(
                continuationToken: extractedResult.continuationToken,
                results: extractedResult.results
            )
        }
    }
    
    public struct SortingMode: Sendable {
        public init(label: String, isSelected: Bool, token: String) {
            self.label = label
            self.isSelected = isSelected
            self.token = token
        }
        
        public var label: String
        
        public var isSelected: Bool
        
        public var token: String
    }
    
    private static func getShortsFromSectionRenderer(_ json: JSON) -> [YTVideo] {
        var toReturn: [YTVideo] = []
        for itemSectionContents in json["content", "richShelfRenderer", "contents"].arrayValue {
            guard let video = getVideoFromItemRenderer(itemSectionContents["richItemRenderer"]) else { continue }
            toReturn.append(video)
        }
        
        return toReturn
    }
    
    private static func getVideoFromItemRenderer(_ json: JSON) -> YTVideo? {
        if json["content", "videoRenderer"].exists() {
            return YTVideo.decodeJSON(json: json["content", "videoRenderer"])
        } else {
            return YTVideo.decodeShortFromJSON(json: json["content", "reelItemRenderer"]) ?? YTVideo.decodeShortFromLockupJSON(json: json["content", "shortsLockupViewModel"])
        }
    }
    
    private static func getContinuationToken(_ json: JSON) -> String? {
        return json["continuationEndpoint", "continuationCommand", "token"].string
    }
    
    private static func getLikeStatus(forKey key: String) -> YTLikeStatus? {
        switch key {
        case "TOOLBAR_LIKE_STATE_INDIFFERENT":
            return .nothing
        case "TOOLBAR_LIKE_STATE_LIKED":
            return .liked
        case "TOOLBAR_LIKE_STATE_DISLIKED":
            return .disliked
        default:
            return nil
        }
    }
    
    private static func getHeartedByCreatorState(forKey key: String) -> Bool? {
        switch key {
        case "TOOLBAR_HEART_STATE_HEARTED":
            return true
        case "TOOLBAR_HEART_STATE_UNHEARTED":
            return false
        default:
            return nil
        }
    }
    
    private static func extractCommentRendererTokensFromCommentViewModel(_ json: JSON, loadRepliesContinuationToken: String? = nil) -> CommentRendererTokens? {
        let commentId: String? = json["commentId"].string
        let commentInfo: String? = json["commentKey"].string
        
        guard let commentId = commentId, let commentInfo = commentInfo else { return nil }
        
        let commentAuthData: String? = json["toolbarStateKey"].string
        
        let commentCommands: String? = json["toolbarSurfaceKey"].string
        
        return CommentRendererTokens(commentId: commentId, commentInfo: commentInfo, commentAuthData: commentAuthData, commentCommands: commentCommands, loadRepliesContinuationToken: loadRepliesContinuationToken)
    }
    
    private struct CommentRendererTokens: Sendable {
        let commentId: String
        
        let commentInfo: String
        let commentAuthData: String?
        let commentCommands: String?
        let loadRepliesContinuationToken: String?
    }
}
