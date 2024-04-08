//
//  YTPlaylist+fetchVideos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension YTPlaylist {
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<PlaylistInfosResponse, Error>) -> Void) {
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
    
    
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (PlaylistInfosResponse?, Error?) -> Void) {
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
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> (PlaylistInfosResponse?, Error?) {
        do {
            return await (try self.fetchVideosThrowing(youtubeModel: youtubeModel, useCookies: useCookies), nil)
        } catch {
            return (nil, error)
        }
    }
}
