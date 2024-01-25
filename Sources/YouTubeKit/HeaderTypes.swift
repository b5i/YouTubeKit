//
//  HeaderTypes.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// List of possibles requests where you can send to YouTube
public enum HeaderTypes: Codable {
    /// Get home menu videos.
    case home
    
    /// Get search results.
    /// - Parameter query: Search query
    case search
    
    /// Get search results that have a Creative Commons license.
    /// - Parameter query: Search query
    case restrictedSearch
    
    /// Get streaming infos for a video.
    /// - Parameter query: Video's ID
    case videoInfos
    
    /// Get streaming infos for a video, including adaptative formats.
    /// - Parameter query: Video's ID
    case videoInfosWithDownloadFormats
    
    /// Get autocompletion for query.
    /// - Parameter query: Search query
    case autoCompletion
    
    /// Get channel infos.
    /// - Parameter browseId: Channel's ID
    /// - Parameter params: The operation param (videos, shorts, directs, playlists) (optional)
    case channelHeaders
    
    /// Get playlist's videos.
    /// - Parameter browseId: Playlist's ID (make sure it starts with "VL" if not, add it)
    case playlistHeaders
    
    /// Get playlist's videos (continuation).
    /// - Parameter continuation: Playlist's continuation token
    case playlistContinuationHeaders
    
    /// Get home menu's videos (continuation).
    /// - Parameter continuation: Home menu's continuation token
    /// - Parameter visitorData: The visitorData token.
    case homeVideosContinuationHeader
    
    /// Get search's results (continuation).
    /// - Parameter continuation: Search's continuation token
    /// - Parameter visitorData: The visitorData token **(optional)**
    case searchContinuationHeaders
    
    /// Get channel's results (continuation).
    /// - Parameter continuation: Channel query's continuation token
    case channelContinuationHeaders
    
    /// Get a user's account's infos.
    case userAccountHeaders
    
    /// Get a user's library.
    case usersLibraryHeaders
    
    /// Get all playlists where a video could be added, also includes the info whether the video is already in the playlist or not.
    /// - Parameter browseId: The video's id to check.
    case usersAllPlaylistsHeaders
    
    /// Create a playlist containing a video.
    /// - Parameter query: The playlist's name.
    /// - Parameter params: The playlist's privacy (PRIVATE, UNLISTED, PUBLIC): ``YTPrivacy``.
    /// - Parameter movingVideoId: The video's id.
    case createPlaylistHeaders
    
    /// Move video in playlist.
    /// - Parameter movingVideoId: The videoIdInPlaylist that is moved.
    /// - Parameter videoBeforeId: The videoIdInPlaylist that is just before the place of the moved video, empty if the video is moved at the top of the playlist.
    /// - Parameter browseId: The playlist's id.
    case moveVideoInPlaylistHeaders
    
    /// Remove video from playlist.
    /// - Parameter movingVideoId: The videoIdInPlaylist that is removed.
    /// - Parameter playlistEditToken: The playlist's removal action token.
    /// - Parameter browseId: The playlist's id.
    case removeVideoFromPlaylistHeaders
    
    /// Remove video from playlist.
    /// - Parameter movingVideoId: The video's id that is removed.
    /// - Parameter browseId: The playlist's id.
    case removeVideoByIdFromPlaylistHeaders
    
    /// Add video to playlist (append at the end of it).
    /// - Parameter movingVideoId: The video's id that is added.
    /// - Parameter browseId: The playlist's id.
    case addVideoToPlaylistHeaders
    
    /// Delete a playlist from the account.
    /// - Parameter movingVideoId: The video's `suppressToken`.
    case deletePlaylistHeaders
    
    /// Get the history of the account.
    case historyHeaders
    
    /// Delete a video from the history of the account.
    /// - Parameter browseId: The playlist's id.
    case deleteVideoFromHistory
    
    /// Get more infos about a video (comment, recommanded videos, etc...).
    /// - Parameter query: The video's id.
    case moreVideoInfosHeaders
    
    /// Get more videos of the recommended section in ``MoreVideoInfosResponse``.
    /// - Parameter continuation: The continuation token. (``MoreVideoInfosResponse/recommendedVideosContinuationToken``)
    case fetchMoreRecommendedVideosHeaders
    
    /// Like video.
    /// - Parameter query: The video's id.
    case likeVideoHeaders
    
    /// Dislike video.
    /// - Parameter query: The video's id.
    case dislikeVideoHeaders
    
    /// Remove like/dislike from a video.
    /// - Parameter query: The video's id.
    case removeLikeStatusFromVideoHeaders
        
    /// Subscribe to a channel.
    /// - Parameter browseId: The channel's id.
    case subscribeToChannelHeaders
    
    /// Unsubscribe to a channel.
    /// - Parameter browseId: The channel's id.
    case unsubscribeFromChannelHeaders
    
    /// For custom headers
    case customHeaders(String)
}
