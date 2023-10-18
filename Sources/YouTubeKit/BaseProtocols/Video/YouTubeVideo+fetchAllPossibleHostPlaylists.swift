//
//  YouTubeVideo+fetchAllPossibleHostPlaylists.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension YouTubeVideo {
    /// Get all the user's playlists and if the video is already inside or not.
    func fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel, result: @escaping (AllPossibleHostPlaylistsResponse?, Error?) -> Void) {
        AllPossibleHostPlaylistsResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.videoId], result: result)
    }
    
    /// Get all the user's playlists and if the video is already inside or not.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchAllPossibleHostPlaylists(youtubeModel: YouTubeModel) async -> (AllPossibleHostPlaylistsResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(AllPossibleHostPlaylistsResponse?, Error?), Never>) in
            fetchAllPossibleHostPlaylists(youtubeModel: youtubeModel, result: { response, error in
                continuation.resume(returning: (response, error))
            })
        })
    }
}
