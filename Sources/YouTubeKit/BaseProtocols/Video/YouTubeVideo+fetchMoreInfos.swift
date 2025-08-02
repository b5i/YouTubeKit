//
//  YouTubeVideo+fetchMoreInfos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension YouTubeVideo {
    func fetchMoreInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<MoreVideoInfosResponse, Error>) -> ()) {
        MoreVideoInfosResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], useCookies: useCookies, result: result)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchMoreInfosThrowing(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> MoreVideoInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<MoreVideoInfosResponse, Error>) in
            self.fetchMoreInfos(youtubeModel: youtubeModel, useCookies: useCookies, result: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchMoreInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (MoreVideoInfosResponse?, Error?) -> ()) instead.") // safer and better to use the Result API instead of a tuple
    func fetchMoreInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (MoreVideoInfosResponse?, Error?) -> ()) {
        self.fetchMoreInfos(youtubeModel: youtubeModel, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchMoreInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> MoreVideoInfosResponse instead.") // safer and better to use the throws API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchMoreInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> (MoreVideoInfosResponse?, Error?) {
        do {
            return await (try self.fetchMoreInfosThrowing(youtubeModel: youtubeModel, useCookies: useCookies), nil)
        } catch {
            return (nil, error)
        }
    }
}
