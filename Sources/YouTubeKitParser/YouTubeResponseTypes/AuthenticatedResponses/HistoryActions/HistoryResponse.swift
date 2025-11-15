//
//  HistoryResponse.swift
//
//
//  Created by Antoine Bollengier on 03.01.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Struct representing a HistoryResponse to get the infos and the videos from the account's history.
public struct HistoryResponse: AuthenticatedContinuableResponse {
    public static let headersType: HeaderTypes = .historyHeaders
    
    public static let parametersValidationList: ValidationList = [:]
    
    /// ID of the playlist.
    public static let playlistId: String = "VLFEhistory"
    
    public var isDisconnected: Bool = true
    
    /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
    public var continuationToken: String?
    
    public var visitorData: String? = nil
    
    /// Array of groups of videos and their "watched" date.
    ///
    /// Example:
    /// ```swift
    /// var results = [HistoryBlock(groupTitle: "Today", contentsArray: [A few videos or shorts]), (groupTitle: "Yesterday", contentsArray: [A few videos too])]
    /// ```
    public var results: [HistoryBlock] = []
    
    @available(*, deprecated, renamed: "results")
    public var videosAndTime: [HistoryBlock] {
        return results
    }
    
    /// Title of the playlist.
    public var title: String?
    
    public static func decodeJSON(json: JSON) -> HistoryResponse {
        var toReturn = HistoryResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        guard let tabJSON = json["contents", "twoColumnBrowseResultsRenderer", "tabs"].array?.first(where: {$0["tabRenderer", "selected"].bool == true})?["tabRenderer"], tabJSON["tabIdentifier"].string == "FEhistory" else { return toReturn }
        
        toReturn.title = json["header", "pageHeaderRenderer", "pageTitle"].string
        
        let responseContents = tabJSON["content", "sectionListRenderer", "contents"].arrayValue
        
        for contentGroup in responseContents {
            if contentGroup["itemSectionRenderer"].exists() {
                let videoGroup = contentGroup["itemSectionRenderer"]

                let historyBlock = self.decodeHistoryBlock(historyBlockJSON: videoGroup)

                if !historyBlock.contentsArray.isEmpty {
                    toReturn.results.append(historyBlock)
                }
            } else if contentGroup["continuationItemRenderer"].exists() {
                toReturn.continuationToken = contentGroup["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string
            }
        }
        
        return toReturn
    }
    
    static func decodeHistoryBlock(historyBlockJSON: JSON) -> HistoryBlock {
        let title = historyBlockJSON["header", "itemSectionHeaderRenderer", "title", "runs"].array?.map({$0["text"].stringValue}).joined() ?? historyBlockJSON["header", "itemSectionHeaderRenderer", "title", "simpleText"].stringValue
        var toAppend: HistoryBlock = .init(groupTitle: title, contentsArray: [])
        for videoJSON in historyBlockJSON["contents"].arrayValue {
            if let video = YTVideo.decodeJSON(json: videoJSON["videoRenderer"]) {
                let block = HistoryBlock.VideoWithToken(video: video, suppressToken: videoJSON["videoRenderer", "menu", "menuRenderer", "topLevelButtons"].array?.first?["buttonRenderer", "serviceEndpoint", "feedbackEndpoint", "feedbackToken"].string)
                toAppend.contentsArray.append(block)
            } else if videoJSON["reelShelfRenderer"].exists() {
                var block = HistoryBlock.ShortsBlock(shorts: [], suppressTokens: [])
                for shortJSON in videoJSON["reelShelfRenderer", "items"].arrayValue {
                    if let short = YTVideo.decodeShortFromJSON(json: shortJSON["reelItemRenderer"]) ?? YTVideo.decodeShortFromLockupJSON(json: shortJSON["shortsLockupViewModel"]) {
                        block.shorts.append(short)
                        block.suppressTokens.append(shortJSON["reelItemRenderer", "menu", "menuRenderer", "items", 0, "menuServiceItemRenderer", "serviceEndpoint", "feedbackEndpoint", "feedbackToken"].string)
                    }
                }
                toAppend.contentsArray.append(block)
            }
        }
        return toAppend
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: AuthenticatedResponse, ResponseContinuation {
        public static let headersType: HeaderTypes = .historyContinuationHeaders
        
        public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
        public var isDisconnected: Bool = true
        
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of history blocks.
        public var results: [HistoryBlock] = []
        
        public static func decodeJSON(json: JSON) -> HistoryResponse.Continuation {
            var toReturn = Continuation()
            
            guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
            
            toReturn.isDisconnected = false
            
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            for continationAction in continuationActionsArray {
                guard let continuationItemsArray = continationAction["appendContinuationItemsAction", "continuationItems"].array else { continue }
                for contentGroup in continuationItemsArray {
                    if contentGroup["itemSectionRenderer"].exists() {
                        let videoGroup = contentGroup["itemSectionRenderer"]

                        let historyBlock = HistoryResponse.decodeHistoryBlock(historyBlockJSON: videoGroup)

                        if !historyBlock.contentsArray.isEmpty {
                            toReturn.results.append(historyBlock)
                        }
                    } else if contentGroup["continuationItemRenderer"].exists() {
                        toReturn.continuationToken = contentGroup["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string
                    }
                }
            }
            return toReturn
        }
    }
    
    /// Struct representing a block of history, containing a title and an array of YTVideos.
    public struct HistoryBlock: Hashable, Identifiable, Sendable {
        public static func == (lhs: HistoryResponse.HistoryBlock, rhs: HistoryResponse.HistoryBlock) -> Bool {
            return lhs.id == rhs.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(groupTitle)
            for item in contentsArray {
                hasher.combine(item)
            }
        }
        
        public var id: Int { return self.hashValue }
        
        /// Ttitle of the group, usually represent a part of the time in the history like "Today", "Yesterday" or "February 15".
        public let groupTitle: String
        
        /// An array of the videos that have been watched in the part of time indicated by the HistoryResponse/HistoryBlock/groupTitle.
        public var contentsArray: [any HistoryBlockContent]
        
        @available(*, deprecated, renamed: "contentsArray")
        public var videosArray: [VideoWithToken] {
            return contentsArray.map({ block in
                if let block = block as? VideoWithToken {
                    return [block]
                } else if let block = block as? ShortsBlock {
                    var finalArray: [VideoWithToken] = []
                    for (offset, short) in block.shorts.enumerated() {
                        finalArray.append(VideoWithToken(video: short, suppressToken: block.suppressTokens[offset]))
                    }
                    return finalArray
                } else {
                    return []
                }
            }).reduce([], {
                var finalArray: [VideoWithToken] = []
                
                finalArray.append(contentsOf: $0)
                finalArray.append(contentsOf: $1)
                
                return finalArray
            })
        }
            
        /// Struct representing a video and the token that should be used to suppress it from the history.
        public struct VideoWithToken: HistoryBlockContent, Identifiable, Hashable {
            public var id: Int { self.hashValue }
            
            public let video: YTVideo
            
            /// Token that can be used to remove the video from the history, using for example HistoryResponse/removeVideo(withSuppressToken:youtubeModel:).
            public let suppressToken: String?
        }
        
        public struct ShortsBlock: HistoryBlockContent, Identifiable, Hashable {
            public var id: Int { return self.hashValue }
            
            /// An array containing some shorts.
            public var shorts: [YTVideo]
            
            /// An array containing the suppressToken that should be used to suppress a short from the history, are in the same order as the shorts in ``shorts``.
            public var suppressTokens: [String?]
        }
    }
}
