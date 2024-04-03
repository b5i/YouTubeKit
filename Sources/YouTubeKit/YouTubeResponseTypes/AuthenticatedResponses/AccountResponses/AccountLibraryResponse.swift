//
//  AccountLibraryResponse.swift
//
//
//  Created by Antoine Bollengier on 15.10.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct AccountLibraryResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .usersLibraryHeaders
    
    public static var parametersValidationList: ValidationList = [:]
        
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
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        if let accountStats = json["contents"]["twoColumnBrowseResultsRenderer"]["secondaryContents"]["profileColumnRenderer"]["items"].arrayValue.first(where: {$0["profileColumnStatsRenderer"].exists()})?["profileColumnStatsRenderer"] {
            for accountStatEntry in accountStats["items"].arrayValue {
                toReturn.accountStats.append(
                    (
                        accountStatEntry["profileColumnStatsEntryRenderer"]["label"]["runs"].arrayValue.map({return $0["text"].stringValue}).joined(separator: " "),
                        accountStatEntry["profileColumnStatsEntryRenderer"]["value"]["simpleText"].stringValue
                    )
                )
            }
        }
        
        for libraryTab in json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"].arrayValue {
            if libraryTab["tabRenderer"]["tabIdentifier"].string == "FElibrary" {
                for libraryContentItem in libraryTab["tabRenderer"]["content"]["sectionListRenderer"]["contents"].arrayValue {
                    for libraryContentItemContents in libraryContentItem["itemSectionRenderer"]["contents"].arrayValue {
                        if libraryContentItem["itemSectionRenderer"]["targetId"].string == "library-playlists-shelf" {
                            for playlist in libraryContentItemContents["shelfRenderer"]["content"]["horizontalListRenderer"]["items"].arrayValue {
                                if let decodedPlaylist = YTPlaylist.decodeJSON(json: playlist["gridPlaylistRenderer"]) {
                                    toReturn.playlists.append(decodedPlaylist)
                                }
                            }
                        } else {
                            if let browseId = libraryContentItemContents["shelfRenderer"]["endpoint"]["browseEndpoint"]["browseId"].string {
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
                }
                break
            }
        }

        return toReturn
    }
    
    /// Decode history, likes, etc..
    private static func decodeDefaultPlaylist(playlist: inout YTPlaylist, json: JSON) {
        playlist.title = json["title"]["runs"].arrayValue.map({return $0["text"].stringValue}).joined(separator: " ")
        playlist.videoCount = json["titleAnnotation"]["simpleText"].string
        for frontVideo in json["content"]["horizontalListRenderer"]["items"].arrayValue {
            if let video = YTVideo.decodeJSON(json: frontVideo["gridVideoRenderer"]) {
                playlist.frontVideos.append(video)
            }
        }
    }
}
