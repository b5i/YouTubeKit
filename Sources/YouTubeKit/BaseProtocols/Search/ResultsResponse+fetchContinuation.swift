//
//  ResultsResponse+fetchContinuation.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension ResultsResponse {
    func fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<Continuation, Error>) -> Void) {
        if let continuationToken = continuationToken {
            if let visitorData = visitorData {
                Continuation.sendRequest(youtubeModel: youtubeModel, data: [.continuation: continuationToken, .visitorData: visitorData], useCookies: useCookies, result: result)
            } else {
                Continuation.sendRequest(youtubeModel: youtubeModel, data: [.continuation: continuationToken], useCookies: useCookies, result: result)
            }
        } else {
            result(.failure("Continuation token is not defined."))
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> Continuation {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Continuation, Error>) in
            fetchContinuation(youtubeModel: youtubeModel, useCookies: useCookies, result: { response in
                continuation.resume(with: response)
            })
        })
    }
}
