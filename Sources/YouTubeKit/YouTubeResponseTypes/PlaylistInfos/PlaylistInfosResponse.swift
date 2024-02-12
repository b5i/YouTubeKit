//
//  PlaylistInfosResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 27.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a PlaylistInfosResponse to get the infos and the videos from a playlist.
public struct PlaylistInfosResponse: ResultsResponse {
    public static var headersType: HeaderTypes = .playlistHeaders
    
    /// Channel(s) that own(s) the playlist.
    public var channel: [YTLittleChannelInfos] = []
    
    /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
    public var continuationToken: String?
    
    /// Videos of the playlists.
    public var results: [any YTSearchResult] = []
            
    /// Description of the playlist.
    public var playlistDescription: String?
    
    /// ID of the playlist.
    public var playlistId: String?
    
    /// Privacy type of the playlist.
    public var privacy: YTPrivacy?
    
    /// Array of thumbnails of the playlist.
    public var thumbnails: [YTThumbnail] = []
    
    /// Title of the playlist.
    public var title: String?
    
    /// Possible user interactions with the playlist.
    public var userInteractions: UserInteractions = .init()
    
    /// String representing the count of videos of the playlist.
    public var videoCount: String?
    
    /// String representing the count of views of the playlist.
    public var viewCount: String?
    
    /// Ids related to the playlist of the videos used in the reques and generally only defined when the ``YouTubeModel/cookies``  and only if the user owns the playlist. The n-th id correspond to the n-th result in ``PlaylistInfosResponse/results``.
    public var videoIdsInPlaylist: [String?]?
    
    public var visitorData: String? = nil
    
    public static func decodeData(data: Data) -> PlaylistInfosResponse {
        let json = JSON(data)
        var toReturn = PlaylistInfosResponse()
        
        let playlistInfosJSON = json["header"]["playlistHeaderRenderer"]
        let playlistVideoListRendererJSON = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"].array?[0]["tabRenderer"]["content"]["sectionListRenderer"]["contents"].array?[0]["itemSectionRenderer"]["contents"].array?[0]["playlistVideoListRenderer"]
        
        if let channelInfosArray = playlistInfosJSON["ownerText"]["runs"].array {
            for channelInfosPart in channelInfosArray {
                guard let channelId = channelInfosPart["navigationEndpoint"]["browseEndpoint"]["browseId"].string else { continue }
                
                let newChannel = YTLittleChannelInfos(channelId: channelId, name: channelInfosPart["text"].string)
                toReturn.channel.append(newChannel)
            }
        }
        
        toReturn.playlistDescription = playlistInfosJSON["descriptionText"]["simpleText"].string
        
        if let playlistId = playlistInfosJSON["playlistId"].string {
            /// The request wouldn't work if we don't add a "VL" before the playlistId.
            toReturn.playlistId = "VL" + playlistId
        }
        
        toReturn.privacy = YTPrivacy(rawValue: playlistInfosJSON["privacy"].stringValue)
        
        YTThumbnail.appendThumbnails(json: playlistInfosJSON["playlistHeaderBanner"]["heroPlaylistThumbnailRenderer"]["thumbnail"], thumbnailList: &toReturn.thumbnails)
        
        toReturn.title = playlistInfosJSON["title"]["simpleText"].string
        
        if let videoCountArray = playlistInfosJSON["numVideosText"]["runs"].array {
            toReturn.videoCount = videoCountArray.map({$0["text"].stringValue}).joined()
        }
        
        toReturn.viewCount = playlistInfosJSON["viewCountText"]["simpleText"].string
        
        toReturn.userInteractions.canBeDeleted = playlistInfosJSON["editableDetails"]["canDelete"].bool
        
        toReturn.userInteractions.isSaveButtonDisabled = playlistInfosJSON["saveButton"]["toggleButtonRenderer"]["isDisabled"].bool
        
        toReturn.userInteractions.isSaveButtonToggled = playlistInfosJSON["saveButton"]["toggleButtonRenderer"]["isToggled"].bool
        
        guard let videoTabsArray = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"].array else { return toReturn }
        
        for videoTab in videoTabsArray {
            guard videoTab["tabRenderer"]["selected"].bool == true else { continue }
            
            guard let secondVideoArray = videoTab["tabRenderer"]["content"]["sectionListRenderer"]["contents"].array else { continue }
            for secondVideoArrayPart in secondVideoArray {
                guard let thirdVideoArray = secondVideoArrayPart["itemSectionRenderer"]["contents"].array else { continue }
                
                for thirdVideoArrayPart in thirdVideoArray {
                    let secondHeader = thirdVideoArrayPart["playlistVideoListRenderer"]

                    toReturn.userInteractions.isEditable = playlistInfosJSON["isEditable"].bool ?? secondHeader["isEditable"].bool

                    toReturn.userInteractions.canReorder = playlistInfosJSON["canReorder"].bool ?? secondHeader["canReorder"].bool

                    if toReturn.userInteractions.isEditable ?? false {
                        toReturn.videoIdsInPlaylist = []
                    }
                    guard let finalVideoArray = thirdVideoArrayPart["playlistVideoListRenderer"]["contents"].array else { continue }
                    for videoJSON in finalVideoArray {
                        if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoRenderer"]) {
                            
                            toReturn.videoIdsInPlaylist?.append(videoJSON["playlistVideoRenderer"]["setVideoId"].string)
                            
                            toReturn.results.append(video)
                        } else if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoListRenderer"]) {
                            
                            toReturn.videoIdsInPlaylist?.append(videoJSON["playlistVideoListRenderer"]["setVideoId"].string)
                            
                            toReturn.results.append(video)
                        } else if let continuationToken = videoJSON["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string {
                            toReturn.continuationToken = continuationToken
                        }
                    }
                }
            }
        }
        
        return toReturn
    }
    
    /// Merge a ``PlaylistInfosResponse/Continuation`` to this instance of ``PlaylistInfosResponse``.
    /// - Parameter continuation: the ``PlaylistInfosResponse/Continuation`` that will be merged.
    public mutating func mergeWithContinuation(_ continuation: Continuation) {
        self.continuationToken = continuation.continuationToken
        self.results.append(contentsOf: continuation.results.filter({$0 as? YTVideo != nil}) as! [YTVideo])
        self.videoIdsInPlaylist?.append(contentsOf: continuation.videoIdsInPlaylist)
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: ResultsContinuationResponse {
        public static var headersType: HeaderTypes = .playlistContinuationHeaders
        
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of videos.
        public var results: [any YTSearchResult] = []
        
        /// Ids related to the playlist of the videos, generally only defined when the ``YouTubeModel/cookies`` are defined, used in the request and the user owns the playlist.
        public var videoIdsInPlaylist: [String?] = []
        
        public static func decodeData(data: Data) -> PlaylistInfosResponse.Continuation {
            let json = JSON(data)
            
            var toReturn = Continuation()
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            for continationAction in continuationActionsArray {
                guard let continuationItemsArray = continationAction["appendContinuationItemsAction"]["continuationItems"].array else { continue }
                for videoJSON in continuationItemsArray {
                    if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoRenderer"]) {
                        
                        toReturn.videoIdsInPlaylist.append(videoJSON["playlistVideoRenderer"]["setVideoId"].string)
                        
                        toReturn.results.append(video)
                    } else if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoListRenderer"]) {
                        
                        toReturn.videoIdsInPlaylist.append(videoJSON["playlistVideoListRenderer"]["setVideoId"].string)
                        
                        toReturn.results.append(video)
                    } else if let continuationToken = videoJSON["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string {
                        toReturn.continuationToken = continuationToken
                    }
                }
            }
            return toReturn
        }
    }
    
    /// Struct representing the informations about what the user's can do with it.
    public struct UserInteractions {
        public init(canBeDeleted: Bool? = nil, canReorder: Bool? = nil, isEditable: Bool? = nil, isSaveButtonDisabled: Bool? = nil, isSaveButtonToggled: Bool? = nil) {
            self.canBeDeleted = canBeDeleted
            self.canReorder = canReorder
            self.isEditable = isEditable
            self.isSaveButtonDisabled = isSaveButtonDisabled
            self.isSaveButtonToggled = isSaveButtonToggled
        }
        
        /// Boolean indicating if the playlist can be deleted by the user.
        public var canBeDeleted: Bool?
        
        /// Boolean indicating if the playlist can be reordered by the user (history for example could not). Generally defined only when the account owns the playlist.
        public var canReorder: Bool?
        
        /// Boolean indicating if the playlist can be modified by the user.
        public var isEditable: Bool?
        
        /// Boolean indicating if the playlist can be saved by the user.
        public var isSaveButtonDisabled: Bool?
        
        /// Boolean indicating if the playlist is already saved by the user.
        public var isSaveButtonToggled: Bool?
    }
}
