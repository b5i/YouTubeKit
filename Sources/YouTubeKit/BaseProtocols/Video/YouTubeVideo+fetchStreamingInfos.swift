//
//  YouTubeVideo+fetchStreamingInfos.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YouTubeVideo {
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil,
        infos: @escaping (Result<VideoInfosResponse, Error>) -> ()
    ) {
        VideoInfosResponse.sendRequest(
            youtubeModel: youtubeModel,
            data: [.query: videoId],
            useCookies: useCookies,
            result: infos
        )
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil
    ) async throws -> VideoInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<VideoInfosResponse, Error>) in
            fetchStreamingInfos(youtubeModel: youtubeModel, useCookies: useCookies, infos: { result in
                continuation.resume(with: result)
            })
        })
    }
}
