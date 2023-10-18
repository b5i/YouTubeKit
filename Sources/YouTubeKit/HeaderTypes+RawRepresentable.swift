//
//  HeadersList+RawRepresentable.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 19.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

extension HeaderTypes: RawRepresentable {
    
    public init?(rawValue: String) {
        return nil
    }
    
    public var rawValue: String {
        switch self {
        case .home:
            return "home"
        case .search:
            return "search"
        case .restrictedSearch:
            return "restrictedSearch"
        case .videoInfos:
            return "videoInfos"
        case .videoInfosWithDownloadFormats:
            return "videoInfosWithAdaptative"
        case .autoCompletion:
            return "autoCompletion"
        case .channelHeaders:
            return "channelHeaders"
        case .playlistHeaders:
            return "playlistHeaders"
        case .playlistContinuationHeaders:
            return "playlistContinuationHeaders"
        case .homeVideosContinuationHeader:
            return "homeVideosContinuationHeader"
        case .searchContinuationHeaders:
            return "searchContinuationHeaders"
        case .channelContinuationHeaders:
            return "channelContinuationHeaders"
        case .userAccountHeaders:
            return "userAccountHeaders"
        case .usersLibraryHeaders:
            return "usersLibraryHeaders"
        case .usersAllPlaylistsHeaders:
            return "usersAllPlaylistsHeaders"
        case .createPlaylistHeaders:
            return "createPlaylistHeaders"
        case .moveVideoInPlaylistHeaders:
            return "moveVideoInPlaylistHeaders"
        case .removeVideoFromPlaylistHeaders:
            return "removeVideoFromPlaylistHeaders"
        case .removeVideoByIdFromPlaylistHeaders:
            return "removeVideoByIdFromPlaylistHeaders"
        case .addVideoToPlaylistHeaders:
            return "addVideoToPlaylistHeaders"
        case .deletePlaylistHeaders:
            return "deletePlaylistHeaders"
        case .moreVideoInfosHeaders:
            return "moreVideoInfosHeaders"
        case .fetchMoreRecommendedVideosHeaders:
            return "fetchMoreRecommendedVideosHeaders"
        case .likeVideoHeaders:
            return "likeVideoHeaders"
        case .dislikeVideoHeaders:
            return "dislikeVideoHeaders"
        case .removeLikeStatusFromVideoHeaders:
            return "removeLikeStatusFromVideoHeaders"
        case .subscribeToChannelHeaders:
            return "subscribeToChannelHeaders"
        case .unsubscribeFromChannelHeaders:
            return "unsubscribeFromChannelHeaders"
        case .customHeaders(let stringIdentifier):
            return stringIdentifier
        }
    }
    
    public typealias RawValue = String
    
}
