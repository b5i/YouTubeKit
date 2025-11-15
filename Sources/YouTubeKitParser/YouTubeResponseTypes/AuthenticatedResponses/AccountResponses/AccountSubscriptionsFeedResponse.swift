//
//  AccountSubscriptionsFeedResponse.swift
//  
//
//  Created by Antoine Bollengier on 02.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

/// A response to get the latest video from channels the YouTubeModel's account is subscribed to.
public struct AccountSubscriptionsFeedResponse: AuthenticatedContinuableResponse {
    public static let headersType: HeaderTypes = .usersSubscriptionsFeedHeaders
    
    public static let parametersValidationList: ValidationList = [:]
    
    public var isDisconnected: Bool = true
    
    public var results: [YTVideo] = []
    
    public var continuationToken: String? = nil
    
    public var visitorData: String? = nil // will never be filled
    
    public static func decodeJSON(json: JSON) throws -> AccountSubscriptionsFeedResponse {
        var toReturn = AccountSubscriptionsFeedResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        guard let tab = json["contents", "twoColumnBrowseResultsRenderer", "tabs"].arrayValue.first(where: {
            return $0["tabRenderer", "selected"].boolValue
        }), tab["tabRenderer", "tabIdentifier"].string == "FEsubscriptions" else {
            throw ResponseExtractionError(reponseType: Self.self, stepDescription: "Error while trying the get the tab of the subscriptions.")
        }
        
        for section in tab["tabRenderer", "content", "richGridRenderer", "contents"].arrayValue {
            if section["richItemRenderer"].exists() {
                guard let video = self.getVideoFromItemRenderer(section["richItemRenderer"]) else { continue }
                toReturn.results.append(video)
            } else if section["richSectionRenderer"].exists() {
                let videos = self.getShortsFromSectionRenderer(section["richSectionRenderer"])
                toReturn.results.append(contentsOf: videos)
            } else if section["continuationItemRenderer"].exists() {
                toReturn.continuationToken =  getContinuationToken(section["continuationItemRenderer"])
            }
        }
        
        return toReturn
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: AuthenticatedResponse, ResponseContinuation {
        public static let headersType: HeaderTypes = .usersSubscriptionsContinuationHeaders
        
        public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
        public var isDisconnected: Bool = true
        
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of videos.
        public var results: [YTVideo] = []
        
        public static func decodeJSON(json: JSON) -> AccountSubscriptionsFeedResponse.Continuation {
            var toReturn = Continuation()
            
            guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
            
            toReturn.isDisconnected = false
            
            for continuationAction in json["onResponseReceivedActions"].arrayValue where continuationAction["appendContinuationItemsAction"].exists() {
                for continuationItem in continuationAction["appendContinuationItemsAction", "continuationItems"].arrayValue {
                    if continuationItem["richItemRenderer"].exists() {
                        guard let video = getVideoFromItemRenderer(continuationItem["richItemRenderer"]) else { continue }
                        toReturn.results.append(video)
                    } else if continuationItem["richSectionRenderer"].exists() {
                        let videos = getShortsFromSectionRenderer(continuationItem["richSectionRenderer"])
                        toReturn.results.append(contentsOf: videos)
                    } else if continuationItem["continuationItemRenderer"].exists() {
                        toReturn.continuationToken = getContinuationToken(continuationItem["continuationItemRenderer"])
                    }
                }
            }
            
            return toReturn
        }
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
}
