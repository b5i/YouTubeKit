//
//  ContinuableResponse+mergeContinuation.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension ContinuableResponse {
    mutating func mergeContinuation(_ continuation: Continuation) {
        self.continuationToken = continuation.continuationToken
        self.results.append(contentsOf: continuation.results)
    }
}
