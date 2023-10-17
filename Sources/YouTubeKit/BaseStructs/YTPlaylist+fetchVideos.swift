//
//  YTPlaylist+fetchVideos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension YTPlaylist {
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (PlaylistInfosResponse?, Error?) -> Void) {
        PlaylistInfosResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.playlistId], useCookies: useCookies, result: result)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Fetch the ``PlaylistInfosResponse`` related to the playlist.
    func fetchVideos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> (PlaylistInfosResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(PlaylistInfosResponse?, Error?), Never>) in
            fetchVideos(youtubeModel: youtubeModel, useCookies: useCookies, result: { response, error in
                continuation.resume(returning: (response, error))
            })
        })
    }
}
