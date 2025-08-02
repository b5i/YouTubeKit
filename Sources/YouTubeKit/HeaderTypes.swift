//
//  HeaderTypes.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// List of possibles requests where you can send to YouTube
public enum HeaderTypes: Codable, Sendable {
    /// Get home menu videos.
    case home
    
    /// Get search results.
    /// - Parameter query: Search query
    case search
    
    /// Get search results that have a Creative Commons license.
    /// - Parameter query: Search query
    case restrictedSearch
    
    /// Get streaming infos for a video.
    /// - Parameter query: Video's ID, should be taken from ``YTVideo/videoId``.
    case videoInfos
    
    /// Get streaming infos for a video, including adaptative formats.
    /// - Parameter query: Video's ID, should be taken from ``YTVideo/videoId``.
    case videoInfosWithDownloadFormats
    
    /// Get autocompletion for query.
    /// - Parameter query: Search query
    case autoCompletion
    
    /// Get channel infos.
    /// - Parameter browseId: Channel's ID, should be taken from ``YTChannel/channelId`` or ``YTLittleChannelInfos/channelId``.
    /// - Parameter params: The operation param (videos, shorts, directs, playlists) (optional)
    case channelHeaders
    
    /// Get playlist's videos.
    /// - Parameter browseId: Playlist's ID (make sure it starts with "VL" if not, add it), should be taken from ``YTPlaylist/playlistId``.
    case playlistHeaders
    
    /// Get playlist's videos (continuation).
    /// - Parameter continuation: Playlist's continuation token, should be taken from ``PlaylistInfosResponse/continuationToken``.
    case playlistContinuationHeaders
    
    /// Get home menu's videos (continuation).
    /// - Parameter continuation: Home menu's continuation token, should be taken from ``HomeScreenResponse/continuationToken``.
    /// - Parameter visitorData: The visitorData token, should be taken from ``HomeScreenResponse/visitorData``.
    case homeVideosContinuationHeader
    
    /// Get search's results (continuation).
    /// - Parameter continuation: Search's continuation token, should be taken from ``SearchResponse/continuationToken``.
    /// - Parameter visitorData: The visitorData token **(optional)**, should be taken from ``SearchResponse/visitorData``.
    case searchContinuationHeaders
    
    /// Get channel's results (continuation).
    /// - Parameter continuation: Channel query's continuation token, should be taken from one of the ids in ``ChannelInfosResponse/channelContentContinuationStore`` depending on the category you want the continuation from.
    case channelContinuationHeaders
    
    /// Get a user's account's infos.
    case userAccountHeaders
    
    /// Get a user's library.
    case usersLibraryHeaders
    
    /// Get all the playlists of a user. Differs from `usersAllPlaylistsHeaders` because it doesn't include the info whether a certain video is already in the playlist or not.
    case usersPlaylistsHeaders
    
    /// Get a user's subscriptions.
    case usersSubscriptionsHeaders
    
    /// Get a user's subscriptions continuation.
    case usersSubscriptionsContinuationHeaders
    
    /// Get a users's subscriptions feed.
    case usersSubscriptionsFeedHeaders
    
    /// Get a users's subscriptions feed continuation.
    case usersSubscriptionsFeedContinuationHeaders
    
    /// Get all playlists where a **video** could be added, also includes the info whether the video is already in the playlist or not.
    /// - Parameter browseId: The video's id to check, should be taken from ``YTVideo/videoId``.
    case usersAllPlaylistsHeaders
    
    /// Create a playlist containing a video.
    /// - Parameter query: The playlist's name.
    /// - Parameter params: The playlist's privacy (PRIVATE, UNLISTED, PUBLIC): ``YTPrivacy``.
    /// - Parameter movingVideoId: The video's id, should be taken from ``YTVideo/videoId``.
    case createPlaylistHeaders
    
    /// Move video in playlist.
    /// - Parameter movingVideoId: The videoIdInPlaylist that is moved.
    /// - Parameter videoBeforeId: The videoIdInPlaylist that is just before the place of the moved video, empty if the video is moved at the top of the playlist.
    /// - Parameter browseId: The playlist's id, should be taken from ``YTPlaylist/playlistId``, make sure it **doesn't** have  "VL" as prefix.
    ///
    /// - Warning: For the attributes that require a "videoIdInPlaylist", you should take the id of the video in ``PlaylistInfosResponse/videoIdsInPlaylist`` and not the default videoId.
    case moveVideoInPlaylistHeaders
    
    /// Remove video from playlist.
    /// - Parameter movingVideoId: The videoIdInPlaylist that is removed.
    /// - Parameter playlistEditToken: The playlist's removal action token.
    /// - Parameter browseId: The playlist's id, should be taken from ``YTPlaylist/playlistId``, make sure that it **doesn't** have "VL" as prefix.
    ///
    /// - Warning: For the attributes that require a "videoIdInPlaylist", you should take the id of the video in ``PlaylistInfosResponse/videoIdsInPlaylist`` and not the default videoId.
    case removeVideoFromPlaylistHeaders
    
    /// Remove video from playlist.
    /// - Parameter movingVideoId: The video's id that is removed, should be taken from ``YTVideo/videoId``.
    /// - Parameter browseId: The playlist's id, should be taken from ``YTPlaylist/playlistId``, make sure it **doesn't** have  "VL" as prefix.
    case removeVideoByIdFromPlaylistHeaders
    
    /// Add video to playlist (append at the end of it).
    /// - Parameter movingVideoId: The video's id that is added, should be taken from ``YTVideo/videoId``.
    /// - Parameter browseId: The playlist's id, should be taken from ``YTPlaylist/playlistId``, make sure it **doesn't** have  "VL" as prefix.
    case addVideoToPlaylistHeaders
    
    /// Delete a playlist from the account.
    /// - Parameter browseId: The playlists's id, should be taken from ``YTPlaylist/playlistId``, make sure it **doesn't** have  "VL" as prefix.
    case deletePlaylistHeaders
    
    /// Get the history of the account.
    /// - Parameter query: Search query in the history (optional)
    case historyHeaders
    
    /// Get the history's continuation.
    /// - Parameter continuation: The continuation token, should be taken from ``HistoryResponse/continuationToken``.
    case historyContinuationHeaders
    
    /// Delete a video from the history of the account.
    /// - Parameter movingVideoId: The videos's suppress token, should be taken from ``HistoryResponse/videosAndTime``'s suppressToken property.
    case deleteVideoFromHistory
    
    /// Get more infos about a video (comment, recommanded videos, etc...).
    /// - Parameter query: The video's id, should be taken from ``YTVideo/videoId``.
    case moreVideoInfosHeaders
    
    /// Get more videos of the recommended section in ``MoreVideoInfosResponse``.
    /// - Parameter continuation: The continuation token, should be taken from ``MoreVideoInfosResponse/recommendedVideosContinuationToken``.
    case fetchMoreRecommendedVideosHeaders
    
    /// Like video.
    /// - Parameter query: The video's id, should be taken from ``YTVideo/videoId``.
    case likeVideoHeaders
    
    /// Dislike video.
    /// - Parameter query: The video's id, should be taken from ``YTVideo/videoId``.
    case dislikeVideoHeaders
    
    /// Remove like/dislike from a video.
    /// - Parameter query: The video's id, should be taken from ``YTVideo/videoId``.
    case removeLikeStatusFromVideoHeaders
        
    /// Subscribe to a channel.
    /// - Parameter browseId: The channel's id, should be taken from ``YTChannel/channelId`` or ``YTLittleChannelInfos/channelId``.
    case subscribeToChannelHeaders
    
    /// Unsubscribe to a channel.
    /// - Parameter browseId: The channel's id should be taken from ``YTChannel/channelId`` or ``YTLittleChannelInfos/channelId``.
    case unsubscribeFromChannelHeaders
    
    /// Get the captions of a video.
    /// - Parameter customURL: The url of the captions that you can get from one of the ``YTCaption/url`` of ``VideoInfosResponse/captions``.
    case videoCaptionsHeaders
    
    /// Get trending videos.
    /// - Parameter params: The operation param from ``TrendingVideosResponse/requestParams`` (optional).
    case trendingVideosHeaders
    
    /// Get a video's comments.
    /// - Parameter continuation: The continuation token from ``MoreVideoInfosResponse/commentsContinuationToken``.
    case videoCommentsHeaders
    
    /// Get a video's comments' continuation.
    /// - Parameter continuation: The continuation token from ``VideoCommentsResponse/continuationToken``.
    case videoCommentsContinuationHeaders
    
    /// Create a comment.
    /// - Parameter params: the params from ``VideoCommentsResponse/commentCreationToken``
    /// - Parameter text: the text of the new comment (no need to escape it).
    case createCommentHeaders
    
    /// Like a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.like], only present if ``YouTubeModel/cookies`` contains valid cookies.
    case likeCommentHeaders
    
    /// Dislike a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.dislike], only present if ``YouTubeModel/cookies`` contains valid cookies.
    case dislikeCommentHeaders
    
    /// Remove the like from a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.removeLike], only present if ``YouTubeModel/cookies`` contains valid cookies.
    case removeLikeCommentHeaders
    
    /// Remove the dislike from a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.removeDislike], only present if ``YouTubeModel/cookies`` contains valid cookies.
    case removeDislikeCommentHeaders
    
    /// Edit the content of a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.edit], only present if ``YouTubeModel/cookies`` contains valid cookies.
    /// - Parameter text: the new text of the comment (no need to escape it).
    case editCommentHeaders
    
    /// Edit the content of a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.edit], only present if ``YouTubeModel/cookies`` contains valid cookies.
    /// - Parameter text: the new text of the comment (no need to escape it).
    case replyCommentHeaders
    
    /// Edit the text of a reply to a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.edit] from the reply, only present if ``YouTubeModel/cookies`` contains valid cookies.
    /// - Parameter text: the new text of the comment (no need to escape it).
    case editReplyCommentHeaders
    
    /// Delete a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.delete], only present if ``YouTubeModel/cookies`` contains valid cookies.
    case removeCommentHeaders
    
    /// Translate the text of a comment.
    /// - Parameter params: the params from ``YTComment/actionsParams``[.translate], only present if ``YouTubeModel/cookies`` contains valid cookies.
    case translateCommentHeaders
    
    /// For custom headers
    case customHeaders(String)
}
