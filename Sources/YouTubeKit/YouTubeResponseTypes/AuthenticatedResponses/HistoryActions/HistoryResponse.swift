//
//  HistoryResponse.swift
//
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import Foundation

/// Struct representing a HistoryResponse to get the infos and the videos from the account's history.
///
/// TODO: Enable the extraction of the continuation token.
public struct HistoryResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .historyHeaders
    
    /// ID of the playlist.
    public static var playlistId: String = "VLFEhistory"
    
    public var isDisconnected: Bool = true
    
    /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
    public var continuationToken: String?
    
    /// Array of groups of videos and their "watched" date.
    ///
    /// Example:
    /// ```swift
    /// var videosAndTime = [("Today", [A few videos]), ("Yesterday", [A few videos too])]
    /// ```
    public var videosAndTime: [(String, [(YTVideo, suppressToken: String?)])] = []
    
    /// Title of the playlist.
    public var title: String?
        
    public static func decodeData(data: Data) -> HistoryResponse {
        let json = JSON(data)
        var toReturn = HistoryResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        guard let tabJSON = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"].array?.first(where: {$0["tabRenderer"]["selected"].bool == true})?["tabRenderer"], tabJSON["tabIdentifier"].string == "FEhistory" else { return toReturn }
        
        toReturn.title = tabJSON["content"]["sectionListRenderer"]["header"]["textHeaderRenderer"]["title"]["runs"].array?.map({$0["text"].stringValue}).joined()

        for videoGroup in tabJSON["content"]["sectionListRenderer"]["contents"].arrayValue.map({$0["itemSectionRenderer"]}) {
            let title = videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["runs"].array?.map({$0["text"].stringValue}).joined() ?? videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["simpleText"].stringValue
            var toAppend: (String , [(YTVideo, String?)]) = (title, [])
            for videoJSON in videoGroup["contents"].arrayValue {
                if let video = YTVideo.decodeJSON(json: videoJSON["videoRenderer"]) {
                    toAppend.1.append((video, videoJSON["videoRenderer"]["menu"]["menuRenderer"]["topLevelButtons"].array?.first?["buttonRenderer"]["serviceEndpoint"]["feedbackEndpoint"]["feedbackToken"].string))
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
        
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of videos.
        public var videosAndTime: [(String, [(YTVideo, suppressToken: String?)])] = []
        
        public static func decodeData(data: Data) -> HistoryResponse.Continuation {
            let json = JSON(data)
            
            var toReturn = Continuation()
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            for continationAction in continuationActionsArray {
                guard let continuationItemsArray = continationAction["appendContinuationItemsAction"]["continuationItems"].array else { continue }
                for videoGroup in continuationItemsArray {
                    let title = videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["runs"].array?.map({$0["text"].stringValue}).joined() ?? videoGroup["header"]["itemSectionHeaderRenderer"]["title"]["simpleText"].stringValue
                    var toAppend: (String , [(YTVideo, String?)]) = (title, [])
                    for videoJSON in videoGroup["contents"].arrayValue {
                        if let video = YTVideo.decodeJSON(json: videoJSON["videoRenderer"]) {
                            toAppend.1.append((video, videoJSON["videoRenderer"]["menu"]["menuRenderer"]["topLevelButtons"].array?.first?["buttonRenderer"]["serviceEndpoint"]["feedbackEndpoint"]["feedbackToken"].string))
                        }
                    }
                    toReturn.videosAndTime.append(toAppend)
                }
            }
            return toReturn
        }
    }
}
