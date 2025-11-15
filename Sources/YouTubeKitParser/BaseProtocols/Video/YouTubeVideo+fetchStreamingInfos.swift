//
//  YouTubeVideo+fetchStreamingInfos.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YouTubeVideo {
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil,
        infos: @escaping @Sendable (Result<VideoInfosResponse, Error>) -> ()
    ) {
        VideoInfosResponse.sendNonThrowingRequest(
            youtubeModel: youtubeModel,
            data: [.query: videoId],
            useCookies: useCookies,
            result: infos
        )
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchStreamingInfosThrowing(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil
    ) async throws -> VideoInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<VideoInfosResponse, Error>) in
            self.fetchStreamingInfos(youtubeModel: youtubeModel, useCookies: useCookies, infos: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchStreamingInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, infos: @escaping (Result<VideoInfosResponse, Error>) -> ()) instead.") // safer and better to use the Result API instead of a tuple
    func fetchStreamingInfos(
            youtubeModel: YouTubeModel,
            useCookies: Bool? = nil,
            infos: @escaping @Sendable (VideoInfosResponse?, Error?) -> ()
    ) {
        self.fetchStreamingInfos(youtubeModel: youtubeModel, useCookies: useCookies, infos: { returning in
            switch returning {
            case .success(let response):
                infos(response, nil)
            case .failure(let error):
                infos(nil, error)
            }
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchStreamingInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> VideoInfosResponse instead.") // safer and better to use the throws API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchStreamingInfos(
            youtubeModel: YouTubeModel,
            useCookies: Bool? = nil
    ) async -> (VideoInfosResponse?, Error?) {
        do {
            return await (try self.fetchStreamingInfosThrowing(youtubeModel: youtubeModel, useCookies: useCookies), nil)
        } catch {
            return (nil, error)
        }
    }
}
