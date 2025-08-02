//
//  AuthenticatedContinuableResponse+fetchContinuation.swift
//
//
//  Created by Antoine Bollengier on 17.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

public extension AuthenticatedContinuableResponse {
    func fetchContinuation(youtubeModel: YouTubeModel, result: @escaping @Sendable (Result<Continuation, Error>) -> Void) {
        if let continuationToken = continuationToken {
            Continuation.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.continuation: continuationToken], result: result)
        } else {
            result(.failure("Continuation token is not defined."))
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuation(youtubeModel: YouTubeModel) async throws -> Continuation {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Continuation, Error>) in
            fetchContinuation(youtubeModel: youtubeModel, result: { response in
                continuation.resume(with: response)
            })
        })
    }
}
