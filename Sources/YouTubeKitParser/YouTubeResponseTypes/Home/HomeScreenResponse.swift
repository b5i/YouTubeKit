//
//  HomeScreenResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 28.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing the request/response of the main YouTube webpage.
public struct HomeScreenResponse: ContinuableResponse {    
    public static let headersType: HeaderTypes = .home
    
    public static let parametersValidationList: ValidationList = [:]
        
    /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
    ///
    /// It should normally never be nil because this is the main webpage with infinite results
    public var continuationToken: String?
    
    /// An array representing the videos from the home screen, can be empty if no cookies were provided.
    public var results: [YTVideo] = []
    
    /// String token that is necessary to give to the continuation request in order to make it to work (it sorts of authenticate the continuation).
    public var visitorData: String?
    
    public static func decodeJSON(json: JSON) -> HomeScreenResponse {
        var toReturn = HomeScreenResponse()
        
        toReturn.visitorData = json["responseContext", "visitorData"].string
        
        guard let tabsArray = json["contents", "twoColumnBrowseResultsRenderer", "tabs"].array else { return toReturn }
        for tab in tabsArray {
            guard tab["tabRenderer", "selected"].bool ?? false else { continue }
            
            guard let videosArray = tab["tabRenderer", "content", "richGridRenderer", "contents"].array else { continue }
            for video in videosArray {
                if video["richItemRenderer", "content", "videoRenderer", "videoId"].string != nil, let decodedVideo = YTVideo.decodeJSON(json: video["richItemRenderer", "content", "videoRenderer"]) {
                    toReturn.results.append(decodedVideo)
                } else if video["richItemRenderer", "content", "lockupViewModel"].exists(), let video = YTVideo.decodeLockupJSON(json: video["richItemRenderer", "content", "lockupViewModel"]) {
                    toReturn.results.append(video)
                } else if let continuationToken = video["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                    toReturn.continuationToken = continuationToken
                }
            }
        }
        
        return toReturn
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: ResponseContinuation {
        public static let headersType: HeaderTypes = .homeVideosContinuationHeader
        
        public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator, .visitorData: .existenceValidator]
                
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        ///
        /// It should normally never be nil because this is the main webpage with infinite results
        public var continuationToken: String?
        
        /// Videos array representing the results of the request.
        public var results: [YTVideo] = []
        
        public static func decodeJSON(json: JSON) -> HomeScreenResponse.Continuation {            
            var toReturn = Continuation()
            
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            
            for continuationAction in continuationActionsArray {
                guard let continuationItemsArray = continuationAction["appendContinuationItemsAction", "continuationItems"].array else { return toReturn }
                
                for video in continuationItemsArray {
                    if video["richItemRenderer", "content", "videoRenderer", "videoId"].string != nil, let decodedVideo = YTVideo.decodeJSON(json: video["richItemRenderer", "content", "videoRenderer"]) {
                        toReturn.results.append(decodedVideo)
                    } else if video["richItemRenderer", "content", "lockupViewModel"].exists(), let video = YTVideo.decodeLockupJSON(json: video["richItemRenderer", "content", "lockupViewModel"]) {
                        toReturn.results.append(video)
                    } else if let continuationToken = video["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                        toReturn.continuationToken = continuationToken
                    }
                }
            }
            
            return toReturn
        }
    }
}
