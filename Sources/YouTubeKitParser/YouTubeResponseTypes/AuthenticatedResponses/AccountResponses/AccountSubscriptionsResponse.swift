//
//  AccountSubscriptionsResponse.swift
//  
//
//  Created by Antoine Bollengier on 02.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

/// A response to get all the channels the YouTubeModel's account is subscribed to.
public struct AccountSubscriptionsResponse: AuthenticatedContinuableResponse {
    public static let headersType: HeaderTypes = .usersSubscriptionsHeaders
    
    public static let parametersValidationList: ValidationList = [:]
    
    public var isDisconnected: Bool = true
    
    public var results: [YTChannel] = []
    
    public var continuationToken: String? = nil
    
    public var visitorData: String? = nil // will never be filled
        
    public static func decodeJSON(json: JSON) throws -> AccountSubscriptionsResponse {
        var toReturn = AccountSubscriptionsResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        guard let tab = json["contents", "twoColumnBrowseResultsRenderer", "tabs"].arrayValue.first(where: {
            return $0["tabRenderer", "selected"].boolValue
        }), tab["tabRenderer", "tabIdentifier"].string == "FEchannels" else {
            throw ResponseExtractionError(reponseType: Self.self, stepDescription: "Error while trying the get the tab of the channels.")
        }
        
        for section in tab["tabRenderer", "content", "sectionListRenderer", "contents"].arrayValue {
            if section["itemSectionRenderer"].exists() {
                toReturn.results.append(contentsOf: self.getChannelsFromItemSectionRenderer(section["itemSectionRenderer"]))
            } else if section["continuationItemRenderer"].exists() {
                toReturn.continuationToken = section["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string
            }
        }
        
        return toReturn
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: AuthenticatedResponse, ResponseContinuation {
        public static let headersType: HeaderTypes = .usersSubscriptionsContinuationHeaders
        
        public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
        public var isDisconnected: Bool = true
        
        /// Continuation token used to fetch more channels, nil if there is no more channels to fetch.
        public var continuationToken: String?
        
        /// Array of history blocks.
        public var results: [YTChannel] = []
        
        public static func decodeJSON(json: JSON) -> AccountSubscriptionsResponse.Continuation {
            var toReturn = Continuation()
            
            guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
            
            toReturn.isDisconnected = false
            
            for continuationAction in json["onResponseReceivedActions"].arrayValue where continuationAction["appendContinuationItemsAction"].exists() {
                for continuationItem in continuationAction["appendContinuationItemsAction", "continuationItems"].arrayValue {
                    if continuationItem["itemSectionRenderer"].exists() {
                        toReturn.results.append(contentsOf: getChannelsFromItemSectionRenderer(continuationItem["itemSectionRenderer"]))
                    } else if continuationItem["continuationItemRenderer"].exists() {
                        toReturn.continuationToken = continuationItem["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string
                    }
                }
            }
            
            return toReturn
        }
    }
    
    private static func getChannelsFromItemSectionRenderer(_ json: JSON) -> [YTChannel] {
        var toReturn: [YTChannel] = []
        for itemSectionContents in json["contents"].arrayValue {
            for channelJSON in itemSectionContents["shelfRenderer", "content", "expandedShelfContentsRenderer", "items"].arrayValue {
                guard let channel = YTChannel.decodeJSON(json: channelJSON["channelRenderer"]) else { continue }
                toReturn.append(channel)
            }
        }
        
        return toReturn
    }
}
