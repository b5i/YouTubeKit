//
//  AccountLibraryResponse.swift
//
//
//  Created by Antoine Bollengier on 15.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Response containing some elements of the user's library.
public struct AccountLibraryResponse: AuthenticatedResponse {
    public static let headersType: HeaderTypes = .usersLibraryHeaders
    
    public static let parametersValidationList: ValidationList = [:]
        
    public var isDisconnected: Bool = true
    
    /// Array containing the account's stats.
    ///
    /// It could be for example: (keys are in the account's selected locale)
    /// ```json
    /// [
    ///     ("Subscriptions", "471"),
    ///     ("Uploaded Videos", "12"),
    ///     ("Likes", "5791")
    /// ]
    /// ```
    /// - Note: this category has been removed from YouTube, it will be deprecated in a future version of YouTubeKit.
    public var accountStats: [(key: String, value: String)] = []
    
    /// Playlist containing all the playlists created/added account.
    public var playlists: [YTPlaylist] = []
    
    /// Playlist containing all the video seen by the account.
    ///
    /// - Warning: To fetch the contents of the history you can't use the base ``PlaylistInfosResponse`` but you have to use ``HistoryResponse``.
    public var history: YTPlaylist?
    
    /// Playlist containing all the video that the account added to the Watch Later playlist.
    public var watchLater: YTPlaylist?
    
    /// Playlist containing all the video liked by the account.
    public var likes: YTPlaylist?
            
    public static func decodeJSON(json: JSON) -> AccountLibraryResponse {
        var toReturn = AccountLibraryResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        if let accountStats = json["contents", "twoColumnBrowseResultsRenderer", "secondaryContents", "profileColumnRenderer", "items"].arrayValue.first(where: {$0["profileColumnStatsRenderer"].exists()})?["profileColumnStatsRenderer"] {
            for accountStatEntry in accountStats["items"].arrayValue {
                toReturn.accountStats.append(
                    (
                        accountStatEntry["profileColumnStatsEntryRenderer", "label", "runs"].arrayValue.map({return $0["text"].stringValue}).joined(separator: " "),
                        accountStatEntry["profileColumnStatsEntryRenderer", "value", "simpleText"].stringValue
                    )
                )
            }
        }
        
        for libraryTab in json["contents", "twoColumnBrowseResultsRenderer", "tabs"].arrayValue {
            if libraryTab["tabRenderer", "tabIdentifier"].stringValue.hasSuffix("FElibrary") {
                for libraryContentItem in libraryTab["tabRenderer", "content", "sectionListRenderer", "contents"].array ?? libraryTab["tabRenderer", "content", "richGridRenderer", "contents"].arrayValue {
                    if let libArray = libraryContentItem["itemSectionRenderer", "contents"].array {
                        for libraryContentItemContents in libArray {
                            if libraryContentItem["itemSectionRenderer", "targetId"].string ?? libraryContentItem["itemSectionRenderer", "targetId"].string == "library-playlists-shelf" {
                                let playlistsListRenderer = libraryContentItemContents["shelfRenderer", "content", "horizontalListRenderer", "items"].array ?? libraryContentItemContents["shelfRenderer", "content", "gridRenderer", "items"].arrayValue
                                for playlist in playlistsListRenderer {
                                    if let decodedPlaylist = YTPlaylist.decodeJSON(json: playlist["gridPlaylistRenderer"]) ?? YTPlaylist.decodeLockupJSON(json: playlist["lockupViewModel"]),
                                       !["VLLL", "VLWL", "FEhistory"].contains(decodedPlaylist.playlistId) {
                                        toReturn.playlists.append(decodedPlaylist)
                                    }
                                }
                            } else {
                                if let browseId = libraryContentItemContents["shelfRenderer", "endpoint", "browseEndpoint", "browseId"].string {
                                    switch browseId {
                                    case "FEhistory":
                                        toReturn.history = YTPlaylist(playlistId: "FEhistory")
                                        decodeDefaultPlaylist(playlist: &(toReturn.history!), json: libraryContentItemContents["shelfRenderer"])
                                        break
                                    case "VLWL":
                                        toReturn.watchLater = YTPlaylist(playlistId: "VLWL")
                                        decodeDefaultPlaylist(playlist: &(toReturn.watchLater!), json: libraryContentItemContents["shelfRenderer"])
                                        break
                                    case "VLLL":
                                        toReturn.likes = YTPlaylist(playlistId: "VLLL")
                                        decodeDefaultPlaylist(playlist: &(toReturn.likes!), json: libraryContentItemContents["shelfRenderer"])
                                        break
                                    case "FEclips": // Not supported yet
                                        break
                                    default:
                                        break
                                    }
                                    break
                                }
                            }
                        }
                    } else {
                        self.decodeNextGenLibraryElement(result: &toReturn, json: libraryContentItem)
                    }
                }
                break
            }
        }

        return toReturn
    }
    
    private static func decodeNextGenLibraryElement(result: inout AccountLibraryResponse, json: JSON) {
        switch json["richSectionRenderer", "content", "richShelfRenderer", "endpoint", "browseEndpoint", "browseId"].stringValue {
        case "FEplaylist_aggregation":
            for playlist in json["richSectionRenderer", "content", "richShelfRenderer", "contents"].arrayValue.map({ $0["richItemRenderer", "content"] }) {
                if let decodedPlaylist = YTPlaylist.decodeLockupJSON(json: playlist["lockupViewModel"]),
                   !["VLLL", "VLWL", "FEhistory"].contains(decodedPlaylist.playlistId) {
                    result.playlists.append(decodedPlaylist)
                }
            }
        case "FEhistory":
            result.history = YTPlaylist(playlistId: "FEhistory")
            decodeDefaultPlaylist(playlist: &(result.history!), json: json["richSectionRenderer", "content", "richShelfRenderer", "contents"])
            
            if result.history?.title == nil || result.history?.title == "" {
                result.history?.title = json["richSectionRenderer", "content", "richShelfRenderer", "title", "runs"].array?.map({return $0["text"].stringValue}).joined(separator: " ")
            }
            
            if result.history?.videoCount == nil || result.history?.videoCount == "" {
                result.history?.videoCount = json["richSectionRenderer", "content", "richShelfRenderer", "subtitle", "runs"].array?.map({return $0["text"].stringValue}).joined(separator: " ")
            }
            break
        case "VLWL":
            result.watchLater = YTPlaylist(playlistId: "VLWL")
            decodeDefaultPlaylist(playlist: &(result.watchLater!), json: json["richSectionRenderer", "content", "richShelfRenderer", "contents"])
            
            if result.watchLater?.title == nil || result.watchLater?.title == "" {
                result.watchLater?.title = json["richSectionRenderer", "content", "richShelfRenderer", "title", "runs"].array?.map({return $0["text"].stringValue}).joined(separator: " ")
            }
            
            if result.watchLater?.videoCount == nil || result.watchLater?.videoCount == "" {
                result.watchLater?.videoCount = json["richSectionRenderer", "content", "richShelfRenderer", "subtitle", "runs"].array?.map({return $0["text"].stringValue}).joined(separator: " ")
            }
            break
        case "VLLL":
            result.likes = YTPlaylist(playlistId: "VLLL")
            decodeDefaultPlaylist(playlist: &(result.likes!), json: json["richSectionRenderer", "content", "richShelfRenderer", "contents"])
            
            if result.likes?.title == nil || result.likes?.title == "" {
                result.likes?.title = json["richSectionRenderer", "content", "richShelfRenderer", "title", "runs"].array?.map({return $0["text"].stringValue}).joined(separator: " ")
            }
            
            if result.likes?.videoCount == nil || result.likes?.videoCount == "" {
                result.likes?.videoCount = json["richSectionRenderer", "content", "richShelfRenderer", "subtitle", "runs"].array?.map({return $0["text"].stringValue}).joined(separator: " ")
            }
            break
        case "FEclips": // Not supported yet
            break
        default:
            break
        }
    }
    
    /// Decode history, likes, etc..
    private static func decodeDefaultPlaylist(playlist: inout YTPlaylist, json: JSON) {
        playlist.title = json["title", "runs"].arrayValue.map({return $0["text"].stringValue}).joined(separator: " ")
        playlist.videoCount = json["titleAnnotation", "simpleText"].string
        let frontVideosListRenderer = json["content", "horizontalListRenderer", "items"].array ?? json["content", "gridRenderer", "items"].array ??
            json.arrayValue.map({ $0["richItemRenderer", "content"] })
        for frontVideo in frontVideosListRenderer {
            if let video = YTVideo.decodeJSON(json: frontVideo["gridVideoRenderer"]) ?? YTVideo.decodeJSON(json: frontVideo["videoRenderer"]) ?? YTVideo.decodeLockupJSON(json: frontVideo["lockupViewModel"]) {
                playlist.frontVideos.append(video)
            }
        }
    }
}
