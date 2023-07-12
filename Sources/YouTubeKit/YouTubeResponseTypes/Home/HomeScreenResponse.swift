//
//  HomeScreenResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 28.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing the request/response of the main YouTube webpage.
public struct HomeScreenResponse: ResultsResponse {
    public static var headersType: HeaderTypes = .home
        
    /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
    ///
    /// It should normally never be nil because this is the main webpage with infinite results
    public var continuationToken: String?
    
    /// ``YTSearchResult`` array representing the results of the request.
    ///
    /// There's normally only ``YTVideo`` in the home screen.
    public var results: [any YTSearchResult] = []
    
    /// String token that is necessary to give to the continuation request in order to make it to work (it sorts of authenticate the continuation).
    public var visitorData: String?
    
    public static func decodeData(data: Data) -> HomeScreenResponse {
        let json = JSON(data)
        
        var toReturn = HomeScreenResponse()
        
        toReturn.visitorData = json["responseContext"]["visitorData"].string
        
        guard let tabsArray = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"].array else { return toReturn }
        for tab in tabsArray {
            guard tab["tabRenderer"]["selected"].bool ?? false else { continue }
            
            guard let videosArray = tab["tabRenderer"]["content"]["richGridRenderer"]["contents"].array else { continue }
            for video in videosArray {
                if video["richItemRenderer"]["content"]["videoRenderer"]["videoId"].string != nil, let decodedVideo = YTVideo.decodeJSON(json: video["richItemRenderer"]["content"]["videoRenderer"]) {
                    toReturn.results.append(decodedVideo)
                } else if let continuationToken = video["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string {
                    toReturn.continuationToken = continuationToken
                }
            }
        }
        
        return toReturn
    }
    
    /// Merge a ``HomeScreenResponse/Continuation`` to this instance of ``HomeScreenResponse``.
    /// - Parameter continuation: the ``HomeScreenResponse/Continuation`` that will be merged.
    public mutating func mergeContinuation(_ continuation: Continuation) {
        self.continuationToken = continuation.continuationToken
        self.results.append(contentsOf: continuation.results)
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: ResultsContinuationResponse {
        public static var headersType: HeaderTypes = .homeVideosContinuationHeader
                
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        ///
        /// It should normally never be nil because this is the main webpage with infinite results
        public var continuationToken: String?
        
        /// Videos array representing the results of the request.
        public var results: [any YTSearchResult] = []
        
        public static func decodeData(data: Data) -> HomeScreenResponse.Continuation {
            let json = JSON(data)
            
            var toReturn = Continuation()
            
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            
            for continuationAction in continuationActionsArray {
                guard let continuationItemsArray = continuationAction["appendContinuationItemsAction"]["continuationItems"].array else { return toReturn }
                
                for video in continuationItemsArray {
                    if video["richItemRenderer"]["content"]["videoRenderer"]["videoId"].string != nil, let decodedVideo = YTVideo.decodeJSON(json: video["richItemRenderer"]["content"]["videoRenderer"]) {
                        toReturn.results.append(decodedVideo)
                    } else if let continuationToken = video["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string {
                        toReturn.continuationToken = continuationToken
                    }
                }
            }
            
            return toReturn
        }
    }
}
