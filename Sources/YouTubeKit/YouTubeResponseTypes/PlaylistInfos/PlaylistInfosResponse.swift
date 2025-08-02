//
//  PlaylistInfosResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 27.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Struct representing a PlaylistInfosResponse to get the infos and the videos from a playlist.
public struct PlaylistInfosResponse: ContinuableResponse {
    public static let headersType: HeaderTypes = .playlistHeaders
    
    public static let parametersValidationList: ValidationList = [.browseId: .playlistIdWithVLPrefixValidator]
    
    /// Channel(s) that own(s) the playlist.
    public var channel: [YTLittleChannelInfos] = []
    
    /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
    public var continuationToken: String?
    
    /// Videos of the playlists.
    public var results: [YTVideo] = []
            
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
    
    public static func decodeJSON(json: JSON) -> PlaylistInfosResponse {
        var toReturn = PlaylistInfosResponse()
        
        if json["header", "pageHeaderRenderer"].exists() {
            Self.processNewInfoModel(json: json, response: &toReturn)
        } else {
            Self.processOldInfoModel(json: json, response: &toReturn)
        }
        
        guard let videoTabsArray = json["contents", "twoColumnBrowseResultsRenderer", "tabs"].array else { return toReturn }
        
        for videoTab in videoTabsArray {
            guard videoTab["tabRenderer", "selected"].bool == true else { continue }
            
            if let playlistId = videoTab["tabRenderer", "content", "sectionListRenderer", "targetId"].string {
                if playlistId.hasPrefix("VL") {
                    toReturn.playlistId = playlistId
                } else {
                    toReturn.playlistId = "VL" + playlistId
                }
            }
            
            guard let secondVideoArray = videoTab["tabRenderer", "content", "sectionListRenderer", "contents"].array ?? videoTab["tabRenderer", "content", "playlistVideoListRenderer", "contents"].array else { continue }
            for secondVideoArrayPart in secondVideoArray {
                guard let thirdVideoArray = secondVideoArrayPart["itemSectionRenderer", "contents"].array else { continue }
                
                for thirdVideoArrayPart in thirdVideoArray {
                    guard let finalVideoArray = thirdVideoArrayPart["playlistVideoListRenderer", "contents"].array else { continue }
                    let secondHeader = thirdVideoArrayPart["playlistVideoListRenderer"]

                    toReturn.userInteractions.isEditable = json["header", "playlistHeaderRenderer", "isEditable"].bool ?? secondHeader["isEditable"].bool

                    toReturn.userInteractions.canReorder = json["header", "playlistHeaderRenderer", "canReorder"].bool ?? secondHeader["canReorder"].bool

                    if toReturn.userInteractions.isEditable ?? false {
                        toReturn.videoIdsInPlaylist = []
                    }
                    
                    for videoJSON in finalVideoArray {
                        if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoRenderer"]) {
                            
                            toReturn.videoIdsInPlaylist?.append(videoJSON["playlistVideoRenderer", "setVideoId"].string)
                            
                            toReturn.results.append(video)
                        } else if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoListRenderer"]) {
                            
                            toReturn.videoIdsInPlaylist?.append(videoJSON["playlistVideoListRenderer", "setVideoId"].string)
                            
                            toReturn.results.append(video)
                        } else if videoJSON["continuationItemRenderer", "continuationEndpoint"].exists() {
                            if let token = videoJSON["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                                toReturn.continuationToken = token
                            } else if let commandsArray = videoJSON["continuationItemRenderer", "continuationEndpoint", "commandExecutorCommand", "commands"].array, let token = commandsArray.first(where: {$0["continuationCommand", "token"].string != nil })?["continuationCommand", "token"].string {
                                toReturn.continuationToken = token
                            }
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
        self.results.append(contentsOf: continuation.results)
        self.videoIdsInPlaylist?.append(contentsOf: continuation.videoIdsInPlaylist)
    }
    
    /// Struct representing the continuation ("load more videos" button)
    public struct Continuation: ResponseContinuation {
        public static let headersType: HeaderTypes = .playlistContinuationHeaders
        
        public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
        /// Continuation token used to fetch more videos, nil if there is no more videos to fetch.
        public var continuationToken: String?
        
        /// Array of videos.
        public var results: [YTVideo] = []
        
        /// Ids related to the playlist of the videos, generally only defined when the ``YouTubeModel/cookies`` are defined, used in the request and the user owns the playlist.
        public var videoIdsInPlaylist: [String?] = []
        
        public static func decodeJSON(json: JSON) -> PlaylistInfosResponse.Continuation {
            var toReturn = Continuation()
            guard let continuationActionsArray = json["onResponseReceivedActions"].array else { return toReturn }
            for continationAction in continuationActionsArray {
                guard let continuationItemsArray = continationAction["appendContinuationItemsAction", "continuationItems"].array else { continue }
                for videoJSON in continuationItemsArray {
                    if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoRenderer"]) {
                        
                        toReturn.videoIdsInPlaylist.append(videoJSON["playlistVideoRenderer", "setVideoId"].string)
                        
                        toReturn.results.append(video)
                    } else if let video = YTVideo.decodeVideoFromPlaylist(json: videoJSON["playlistVideoListRenderer"]) {
                        
                        toReturn.videoIdsInPlaylist.append(videoJSON["playlistVideoListRenderer", "setVideoId"].string)
                        
                        toReturn.results.append(video)
                    } else if let continuationToken = videoJSON["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                        toReturn.continuationToken = continuationToken
                    }
                }
            }
            return toReturn
        }
    }
    
    /// Struct representing the informations about what the user's can do with it.
    public struct UserInteractions: Sendable {
        public init(canBeDeleted: Bool? = nil, canReorder: Bool? = nil, isEditable: Bool? = nil, isSaveButtonDisabled: Bool? = nil, isSaveButtonToggled: Bool? = nil) {
            self.canBeDeleted = canBeDeleted
            self.canReorder = canReorder
            self.isEditable = isEditable
            self.isSaveButtonDisabled = isSaveButtonDisabled
            self.isSaveButtonToggled = isSaveButtonToggled
        }
        
        /// Boolean indicating if the playlist can be deleted by the user.
        public var canBeDeleted: Bool?
        
        /// Boolean indicating if the playlist can be reordered by the user (history for example could not). Generally defined only when the account owns the playlist. Non-nil value does not implies that the action can actually be performed, check if ``PlaylistInfosResponse/videoIdsInPlaylist`` is not empty for that.
        public var canReorder: Bool?
        
        /// Boolean indicating if the playlist can be modified by the user. Generally defined only when the account owns the playlist. Non-nil value does not implies that the action can actually be performed, check if ``PlaylistInfosResponse/videoIdsInPlaylist`` is not empty for that.
        public var isEditable: Bool?
        
        /// Boolean indicating if the playlist can be saved by the user.
        public var isSaveButtonDisabled: Bool?
        
        /// Boolean indicating if the playlist is already saved by the user.
        public var isSaveButtonToggled: Bool?
    }
    
    private static func processOldInfoModel(json: JSON, response: inout PlaylistInfosResponse) {
        let playlistInfosJSON = json["header", "playlistHeaderRenderer"]
        
        if let channelInfosArray = playlistInfosJSON["ownerText", "runs"].array {
            for channelInfosPart in channelInfosArray {
                guard let channelId = channelInfosPart["navigationEndpoint", "browseEndpoint", "browseId"].string else { continue }
                
                let newChannel = YTLittleChannelInfos(channelId: channelId, name: channelInfosPart["text"].string)
                response.channel.append(newChannel)
            }
        }
        
        response.playlistDescription = playlistInfosJSON["descriptionText", "simpleText"].string
        
        if let playlistId = playlistInfosJSON["playlistId"].string {
            /// The request wouldn't work if we don't add a "VL" before the playlistId.
            response.playlistId = "VL" + playlistId
        }
        
        response.privacy = YTPrivacy(rawValue: playlistInfosJSON["privacy"].stringValue)
        
        YTThumbnail.appendThumbnails(json: playlistInfosJSON["playlistHeaderBanner", "heroPlaylistThumbnailRenderer", "thumbnail"], thumbnailList: &response.thumbnails)
        
        response.title = playlistInfosJSON["title", "simpleText"].string
        
        if let videoCountArray = playlistInfosJSON["numVideosText", "runs"].array {
            response.videoCount = videoCountArray.map({$0["text"].stringValue}).joined()
        }
        
        response.viewCount = playlistInfosJSON["viewCountText", "simpleText"].string
        
        response.userInteractions.canBeDeleted = playlistInfosJSON["editableDetails", "canDelete"].bool
        
        response.userInteractions.isSaveButtonDisabled = playlistInfosJSON["saveButton", "toggleButtonRenderer", "isDisabled"].bool
        
        response.userInteractions.isSaveButtonToggled = playlistInfosJSON["saveButton", "toggleButtonRenderer", "isToggled"].bool
    }
    
    private static func processNewInfoModel(json: JSON, response: inout PlaylistInfosResponse) {
        response.title = json["header", "pageHeaderRenderer", "pageTitle"].string
        YTThumbnail.appendThumbnails(json: json["header", "pageHeaderRenderer", "content", "pageHeaderViewModel", "heroImage", "contentPreviewImageViewModel"], thumbnailList: &response.thumbnails)
        
        if let channelInfosArray = json["sidebar", "playlistSidebarRenderer", "items"].arrayValue.first(where: {$0["playlistSidebarSecondaryInfoRenderer"].exists()})?["playlistSidebarSecondaryInfoRenderer", "videoOwner", "videoOwnerRenderer"], let channelId = channelInfosArray["navigationEndpoint", "browseEndpoint", "browseId"].string {
            var channel = YTLittleChannelInfos(channelId: channelId)
            channel.name = channelInfosArray["title", "runs"].array?.map({$0["text"].stringValue}).joined()
            YTThumbnail.appendThumbnails(json: channelInfosArray["thumbnail"], thumbnailList: &channel.thumbnails)
            
            response.channel.append(channel)
        }
                
        if let primarySidebarRenderer = json["sidebar", "playlistSidebarRenderer", "items"].arrayValue.first(where: {$0["playlistSidebarPrimaryInfoRenderer"].exists()})?["playlistSidebarPrimaryInfoRenderer"] {
            response.playlistDescription = primarySidebarRenderer["description", "runs"].array?.map({$0["text"].stringValue}).joined()
            
            if let selectedPrivacy = primarySidebarRenderer["privacyForm", "dropdownFormFieldRenderer", "dropdown", "dropdownRenderer", "entries"].arrayValue.first(where: {$0["privacyDropdownItemRenderer", "isSelected"].bool == true})?["privacyDropdownItemRenderer", "icon", "iconType"].stringValue, let privacy = selectedPrivacy.ytkFirstGroupMatch(for: "PRIVACY_([A-Z]+)") {
                response.privacy = YTPrivacy(rawValue: privacy)
            } else if let privacy = primarySidebarRenderer["badges"].arrayValue.first(where: {$0["metadataBadgeRenderer", "icon", "iconType"].stringValue.ytkFirstGroupMatch(for: "PRIVACY_([A-Z]+)") != nil})?["metadataBadgeRenderer", "icon", "iconType"].stringValue.ytkFirstGroupMatch(for: "PRIVACY_([A-Z]+)") {
                response.privacy = YTPrivacy(rawValue: privacy)
            } else {
                response.privacy = .public // assume it's public
            }
        }
                
        // TODO: response.userInteractions.canBeDeleted
        
        // TODO: response.userInteractions.isSaveButtonDisabled
        
        // TODO: response.userInteractions.isSaveButtonToggled
    }
}
