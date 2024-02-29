//
//  ResultsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 12.07.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public protocol ResultsResponse: YouTubeResponse, ResultsContinuationResponse {
    associatedtype Continuation: ResultsContinuationResponse
    
    /// String token that is necessary to give to the continuation request in order to make it to work (it sorts of authenticate the continuation).
    ///
    /// Only present in first ``ResultsResponse``and not in the continuations.
    var visitorData: String? { get set }
    
    /// Merge a ``ResultsResponse/Continuation`` to this instance of ``ResultsResponse``.
    /// - Parameter continuation: the ``ResultsResponse/Continuation`` that will be merged.
    mutating func mergeContinuation(_ continuation: Continuation)
        
    /// Fetch the continuation of the ``ResultsResponse``.
    func fetchContinuation(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        result: @escaping (Result<Continuation, Error>) -> Void
    )
    
    /// Fetch the continuation of the ``ResultsResponse``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuation(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async throws -> Continuation
}
