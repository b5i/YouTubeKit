//
//  ContinuableResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 12.07.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// A protocol describing a ``YouTubeResponse`` that can have a continuation.
public protocol ContinuableResponse: ResponseContinuation {
    associatedtype Continuation: ResponseContinuation where Continuation.ResultsType == ResultsType
    
    /// String token that is necessary to give to the continuation request in order to make it to work (it sorts of authenticate the continuation).
    ///
    /// Only present in first ``ContinuableResponse``and not in the continuations.
    var visitorData: String? { get set }
    
    /// Merge a ``ContinuableResponse/Continuation`` to this instance of ``ContinuableResponse``.
    /// - Parameter continuation: the ``ContinuableResponse/Continuation`` that will be merged.
    mutating func mergeContinuation(_ continuation: Continuation)
        
    /// Fetch the continuation of the ``ContinuableResponse``.
    func fetchContinuation(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        result: @escaping @Sendable (Result<Continuation, Error>) -> Void
    )
    
    /// Fetch the continuation of the ``ContinuableResponse``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuationThrowing(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async throws -> Continuation
}
