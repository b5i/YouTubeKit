//
//  ContinuableResponse+fetchContinuation.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension ContinuableResponse {
    func fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<Continuation, Error>) -> Void) {
        if let continuationToken = continuationToken {
            if let visitorData = visitorData {
                Continuation.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.continuation: continuationToken, .visitorData: visitorData], useCookies: useCookies, result: result)
            } else {
                Continuation.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.continuation: continuationToken], useCookies: useCookies, result: result)
            }
        } else {
            result(.failure("Continuation token is not defined."))
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuationThrowing(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> Continuation {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Continuation, Error>) in
            self.fetchContinuation(youtubeModel: youtubeModel, useCookies: useCookies, result: { response in
                continuation.resume(with: response)
            })
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<Continuation, Error>) -> Void) instead.") // safer and better to use the Result API instead of a tuple
    func fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable ((Continuation)?, Error?) -> Void) {
        self.fetchContinuation(youtubeModel: youtubeModel, useCookies: useCookies, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> Continuation instead.") // safer and better to use the throws API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> ((Continuation)?, Error?) {
        do {
            return await (try self.fetchContinuationThrowing(youtubeModel: youtubeModel, useCookies: useCookies), nil)
        } catch {
            return (nil, error)
        }
    }
}
