//
//  ResponseContinuation.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 12.07.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// A protocol describing the continuation of a response.
public protocol ResponseContinuation: YouTubeResponse {
    associatedtype ResultsType
    
    /// Continuation token used to fetch more results, nil if there is no more results to fetch.
    var continuationToken: String? { get set }
    
    /// Results of the continuation search.
    var results: [ResultsType] { get set }
}
