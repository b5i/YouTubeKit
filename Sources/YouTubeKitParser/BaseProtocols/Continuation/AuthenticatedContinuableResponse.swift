//
//  AuthenticatedContinuableResponse.swift
//
//
//  Created by Antoine Bollengier on 17.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

public typealias AuthenticatedResponseContinuation = AuthenticatedResponse & ResponseContinuation

/// A protocol describing an ``AuthenticatedResponse`` that can have a continuation.
public protocol AuthenticatedContinuableResponse: AuthenticatedResponse, ContinuableResponse where Continuation: AuthenticatedResponseContinuation {
    /// Fetch the continuation of the ``AuthenticatedContinuableResponse``.
    func fetchContinuation(
        youtubeModel: YouTubeModel,
        result: @escaping @Sendable (Result<Continuation, Error>) -> Void
    )
    
    /// Fetch the continuation of the ``AuthenticatedContinuableResponse``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuation(
        youtubeModel: YouTubeModel
    ) async throws -> Continuation
}
