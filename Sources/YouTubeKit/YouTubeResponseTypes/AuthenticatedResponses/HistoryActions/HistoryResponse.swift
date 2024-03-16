//
//  HistoryResponse.swift
//
//
//  Created by Antoine Bollengier on 03.01.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Struct representing a HistoryResponse to get the infos and the videos from the account's history.
public struct HistoryResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .historyHeaders
    
    public static var parametersValidationList: ValidationList = [:]
    
    /// ID of the playlist.
    public static var playlistId: String = "VLFEhistory"
    
    public var isDisconnected: Bool = true
    
    /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
    public var continuationToken: String?
    
    /// Array of groups of videos and their "watched" date.
    ///
    /// Example:
    /// ```swift
    /// var videosAndTime = [HistoryBlock(groupTitle: "Today", contentsArray: [A few videos or shorts]), (groupTitle: "Yesterday", contentsArray: [A few videos too])]
    /// ```
    public var historyParts: [HistoryBlock] = []
    
    /// Title of the playlist.
    public var title: String?
    
    public static func decodeJSON(json: JSON) -> HistoryResponse {
        var toReturn = HistoryResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        guard let tabJSON = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"].array?.first(where: {$0["tabRenderer"]["selected"].bool == true})?["tabRenderer"], tabJSON["tabIdentifier"].string == "FEhistory" else { return toReturn }
        
        toReturn.title = json["header"]["pageHeaderRenderer"]["pageTitle"].string
        
        let responseContents = tabJSON["content"]["sectionListRenderer"]["contents"].arrayValue
        
        for contentGroup in responseContents {
            if contentGroup["itemSectionRenderer"].exists() {
                let videoGroup = contentGroup["itemSectionRenderer"]

                toReturn.historyParts.append(self.decodeHistoryBlock(historyBlockJSON: videoGroup))
            } else if contentGroup["continuationItemRenderer"].exists() {
                toReturn.continuationToken = contentGroup["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string
            }
        }
        
        return toReturn
    }
    
    static func decodeHistoryBlock(historyBlockJSON: JSON) -> HistoryBlock {
        let title = historyBlockJSON["header"]["itemSectionHeaderRenderer"]["title"]["runs"].array?.map({$0["text"].stringValue}).joined() ?? historyBlockJSON["header"]["itemSectionHeaderRenderer"]["title"]["simpleText"].stringValue
        var toAppend: HistoryBlock = .init(groupTitle: title, contentsArray: [])
        for videoJSON in historyBlockJSON["contents"].arrayValue {
            if let video = YTVideo.decodeJSON(json: videoJSON["videoRenderer"]) {
                let block = HistoryBlock.VideoWithToken(video: video, suppressToken: videoJSON["videoRenderer"]["menu"]["menuRenderer"]["topLevelButtons"].array?.first?["buttonRenderer"]["serviceEndpoint"]["feedbackEndpoint"]["feedbackToken"].string)
                toAppend.contentsArray.append(block)
            } else if videoJSON["reelShelfRenderer"].exists() {
                var block = HistoryBlock.ShortsBlock(shorts: [], suppressTokens: [])
                for shortJSON in videoJSON["reelShelfRenderer"]["items"].arrayValue {
                    if let short = YTVideo.decodeShortFromJSON(json: shortJSON["reelItemRenderer"]) {
                        block.shorts.append(short)
                        block.suppressTokens.append(shortJSON["reelItemRenderer"]["menu"]["menuRenderer"]["items"].arrayValue.first?["menuServiceItemRenderer"]["serviceEndpoint"]["feedbackEndpoint"]["feedbackToken"].string)
                    }
                }
                toAppend.contentsArray.append(block)
            }
        }
        return toAppend
    }
    
    /// Merge a ``PlaylistInfosResponse/Continuation`` to this instance of ``PlaylistInfosResponse``.
    /// - Parameter continuation: the ``PlaylistInfosResponse/Continuation`` that will be merged.
    public mutating func mergeWithContinuation(_ continuation: Continuation) {
        self.continuationToken = continuation.continuationToken
        self.historyParts.append(contentsOf: continuation.historyParts)
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: AuthenticatedResponse {
        public static var headersType: HeaderTypes = .historyContinuationHeaders
        
        public static var parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
        public var isDisconnected: Bool = true
        
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of history blocks.
        public var historyParts: [HistoryBlock] = []
        
        public static func decodeJSON(json: JSON) -> HistoryResponse.Continuation {
            var toReturn = Continuation()
            
            guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
            
            toReturn.isDisconnected = false
            
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            for continationAction in continuationActionsArray {
                guard let continuationItemsArray = continationAction["appendContinuationItemsAction"]["continuationItems"].array else { continue }
                for contentGroup in continuationItemsArray {
                    if contentGroup["itemSectionRenderer"].exists() {
                        let videoGroup = contentGroup["itemSectionRenderer"]

                        toReturn.historyParts.append(HistoryResponse.decodeHistoryBlock(historyBlockJSON: videoGroup))
                    } else if contentGroup["continuationItemRenderer"].exists() {
                        toReturn.continuationToken = contentGroup["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string
                    }
                }
            }
            return toReturn
        }
    }
    
    /// Struct representing a block of history, containing a title and an array of YTVideos.
    public struct HistoryBlock: Hashable, Identifiable {
        public static func == (lhs: HistoryResponse.HistoryBlock, rhs: HistoryResponse.HistoryBlock) -> Bool {
            return lhs.id == rhs.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(groupTitle)
            for item in contentsArray {
                hasher.combine(item)
            }
        }
        
        public var id: Int { return groupTitle.hashValue }
        
        /// Ttitle of the group, usually represent a part of the time in the history like "Today", "Yesterday" or "February 15".
        public let groupTitle: String
        
        /// An array of the videos that have been watched in the part of time indicated by the HistoryResponse/HistoryBlock/groupTitle.
        public var contentsArray: [any HistoryBlockContent]
        
        /// Struct representing a video and the token that should be used to suppress it from the history.
        public struct VideoWithToken: HistoryBlockContent, Identifiable {
            public var id: Int { return video.hashValue + (suppressToken?.hashValue ?? 0) }
            
            public let video: YTVideo
            
            /// Token that can be used to remove the video from the history, using for example HistoryResponse/removeVideo(withSuppressToken:youtubeModel:).
            public let suppressToken: String?
        }
        
        public struct ShortsBlock: HistoryBlockContent, Identifiable {
            public var id: Int { return self.shorts.hashValue + self.suppressTokens.hashValue}
            
            /// An array containing some shorts.
            public var shorts: [YTVideo]
            
            /// An array containing the suppressToken that should be used to suppress a short from the history, are in the same order as the shorts in ``shorts``.
            public var suppressTokens: [String?]
        }
    }
}
