//
//  HistoryResponse.swift
//
//
//  Created by Antoine Bollengier on 03.01.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Struct representing a HistoryResponse to get the infos and the videos from the account's history.
///
/// TODO: Enable the extraction of the continuation token.
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
    /// var videosAndTime = [HistoryBlock(groupTitle: "Today", videosArray: [A few videos]), (groupTitle: "Yesterday", videosArray: [A few videos too])]
    /// ```
    public var videosAndTime: [HistoryBlock] = []
    
    /// Title of the playlist.
    public var title: String?
        
    public static func decodeJSON(json: JSON) -> HistoryResponse {
        var toReturn = HistoryResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        guard let tabJSON = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"].array?.first(where: {$0["tabRenderer"]["selected"].bool == true})?["tabRenderer"], tabJSON["tabIdentifier"].string == "FEhistory" else { return toReturn }
        
        toReturn.title = json["header"]["pageHeaderRenderer"]["pageTitle"].string

        for videoGroup in tabJSON["content"]["sectionListRenderer"]["contents"].arrayValue.map({$0["itemSectionRenderer"]}) {
            let title = videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["runs"].array?.map({$0["text"].stringValue}).joined() ?? videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["simpleText"].stringValue
            var toAppend: HistoryBlock = .init(groupTitle: title, videosArray: [])
            for videoJSON in videoGroup["contents"].arrayValue {
                if let video = YTVideo.decodeJSON(json: videoJSON["videoRenderer"]) {
                    toAppend.videosArray.append(.init(video: video, suppressToken: videoJSON["videoRenderer"]["menu"]["menuRenderer"]["topLevelButtons"].array?.first?["buttonRenderer"]["serviceEndpoint"]["feedbackEndpoint"]["feedbackToken"].string))
                }
            }
            toReturn.videosAndTime.append(toAppend)
        }
        
        return toReturn
    }
    
    /// Merge a ``PlaylistInfosResponse/Continuation`` to this instance of ``PlaylistInfosResponse``.
    /// - Parameter continuation: the ``PlaylistInfosResponse/Continuation`` that will be merged.
    public mutating func mergeWithContinuation(_ continuation: Continuation) {
        self.continuationToken = continuation.continuationToken
        self.videosAndTime.append(contentsOf: continuation.videosAndTime)
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: YouTubeResponse {
        public static var headersType: HeaderTypes = .playlistContinuationHeaders
        
        public static var parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of videos.
        public var videosAndTime: [HistoryBlock] = []
        
        public static func decodeJSON(json: JSON) -> HistoryResponse.Continuation {            
            var toReturn = Continuation()
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            for continationAction in continuationActionsArray {
                guard let continuationItemsArray = continationAction["appendContinuationItemsAction"]["continuationItems"].array else { continue }
                for videoGroup in continuationItemsArray {
                    let title = videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["runs"].array?.map({$0["text"].stringValue}).joined() ?? videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["simpleText"].stringValue
                    var toAppend: HistoryBlock = .init(groupTitle: title, videosArray: [])
                    for videoJSON in videoGroup["contents"].arrayValue {
                        if let video = YTVideo.decodeJSON(json: videoJSON["videoRenderer"]) {
                            toAppend.videosArray.append(.init(video: video, suppressToken: videoJSON["videoRenderer"]["menu"]["menuRenderer"]["topLevelButtons"].array?.first?["buttonRenderer"]["serviceEndpoint"]["feedbackEndpoint"]["feedbackToken"].string))
                        }
                    }
                    toReturn.videosAndTime.append(toAppend)
                }
            }
            return toReturn
        }
    }
    /// Struct representing a block of history, containing a title and an array of YTVideos.
        public struct HistoryBlock: Hashable, Identifiable {
            public var id: Int { return groupTitle.hashValue }

            /// Ttitle of the group, usually represent a part of the time in the history like "Today", "Yesterday" or "February 15".
            public let groupTitle: String

            /// An array of the videos that have been watched in the part of time indicated by the HistoryResponse/HistoryBlock/groupTitle.
            public var videosArray: [VideoWithToken]
        }

        /// Struct representing a video and the token that should be used to suppress it from the history.
        public struct VideoWithToken: Hashable, Identifiable {
            public var id: Int { return video.hashValue + (suppressToken?.hashValue ?? 0) }

            public let video: YTVideo

            /// Token that can be used to remove the video from the history, using for example HistoryResponse/removeVideo(withSuppressToken:youtubeModel:).
            public let suppressToken: String?
        }
}
