//
//  ResultsResponse+mergeContinuation.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension ResultsResponse {
    mutating func mergeContinuation(_ continuation: Continuation) {
        self.continuationToken = continuation.continuationToken
        self.results.append(contentsOf: continuation.results)
    }
}
