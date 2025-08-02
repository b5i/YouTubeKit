//
//  YouTubeVideo+fetchAllPossibleHostPlaylists.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension YouTubeVideo {
    /// Get all the user's playlists and if the video is already inside or not.
    func fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel, result: @escaping @Sendable (Result<AllPossibleHostPlaylistsResponse, Error>) -> Void) {
        AllPossibleHostPlaylistsResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.browseId: self.videoId], result: result)
    }
    
    /// Get all the user's playlists and if the video is already inside or not.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchAllPossibleHostPlaylistsThrowing(youtubeModel: YouTubeModel) async throws -> AllPossibleHostPlaylistsResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<AllPossibleHostPlaylistsResponse, Error>) in
            self.fetchAllPossibleHostPlaylists(youtubeModel: youtubeModel, result: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    
    /// Get all the user's playlists and if the video is already inside or not.
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel, result: @escaping (Result<AllPossibleHostPlaylistsResponse, Error>) -> Void) instead.") // safer and better to use the Result API instead of a tuple
    func fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel, result: @escaping @Sendable (AllPossibleHostPlaylistsResponse?, Error?) -> Void) {
        self.fetchAllPossibleHostPlaylists(youtubeModel: youtubeModel, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    /// Get all the user's playlists and if the video is already inside or not.
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel) async throws -> AllPossibleHostPlaylistsResponse instead.") // safer and better to use the throws API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel) async -> (AllPossibleHostPlaylistsResponse?, Error?) {
        do {
            return await (try self.fetchAllPossibleHostPlaylistsThrowing(youtubeModel: youtubeModel), nil)
        } catch {
            return (nil, error)
        }
    }
}
