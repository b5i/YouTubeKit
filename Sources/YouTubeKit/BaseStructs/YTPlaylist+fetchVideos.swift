//
//  YTPlaylist+fetchVideos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension YTPlaylist {
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<PlaylistInfosResponse, Error>) -> Void) {
        PlaylistInfosResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.browseId: self.playlistId], useCookies: useCookies, result: result)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    func fetchVideosThrowing(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> PlaylistInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<PlaylistInfosResponse, Error>) in
            self.fetchVideos(youtubeModel: youtubeModel, useCookies: useCookies, result: { response in
                continuation.resume(with: response)
            })
        })
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> Result<PlaylistInfosResponse, Error> {
        do {
            return try await .success(self.fetchVideosThrowing(youtubeModel: youtubeModel, useCookies: useCookies))
        } catch {
            return .failure(error)
        }
    }
    
    
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<PlaylistInfosResponse, Error>) -> ()) instead.") // safer and better to use the Result API instead of a tuple
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (PlaylistInfosResponse?, Error?) -> Void) {
        self.fetchVideos(youtubeModel: youtubeModel, useCookies: useCookies, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) -> Result<PlaylistInfosResponse, Error> instead.") // safer and better to use the Result API instead of a tuple
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> (PlaylistInfosResponse?, Error?) {
        do {
            return await (try self.fetchVideosThrowing(youtubeModel: youtubeModel, useCookies: useCookies), nil)
        } catch {
            return (nil, error)
        }
    }
}
