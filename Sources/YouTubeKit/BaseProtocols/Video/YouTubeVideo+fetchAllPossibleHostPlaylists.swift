//
//  YouTubeVideo+fetchAllPossibleHostPlaylists.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension YouTubeVideo {
    /// Get all the user's playlists and if the video is already inside or not.
    func fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel, result: @escaping (Result<AllPossibleHostPlaylistsResponse, Error>) -> Void) {
        AllPossibleHostPlaylistsResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.videoId], result: result)
    }
    
    /// Get all the user's playlists and if the video is already inside or not.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel) async throws -> AllPossibleHostPlaylistsResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<AllPossibleHostPlaylistsResponse, Error>) in
            fetchAllPossibleHostPlaylists(youtubeModel: youtubeModel, result: { result in
                continuation.resume(with: result)
            })
        })
    }
}
