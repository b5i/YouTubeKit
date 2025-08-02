//
//  YouTubeChannel+fetchInfos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension YouTubeChannel {
    func fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<ChannelInfosResponse, Error>) -> ()) {
        ChannelInfosResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.browseId: self.channelId], useCookies: useCookies, result: result)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchInfosThrowing(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> ChannelInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<ChannelInfosResponse, Error>) in
            fetchInfos(youtubeModel: youtubeModel, useCookies: useCookies, result: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<ChannelInfosResponse, Error>) -> ()) instead.") // safer and better to use the Result API instead of a tuple
    func fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (ChannelInfosResponse?, Error?) -> ()) {
        self.fetchInfos(youtubeModel: youtubeModel, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> ChannelInfosResponse instead.") // safer and better to use the throws API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> (ChannelInfosResponse?, Error?) {
        do {
            return await (try self.fetchInfosThrowing(youtubeModel: youtubeModel, useCookies: useCookies), nil)
        } catch {
            return (nil, error)
        }
    }
}
