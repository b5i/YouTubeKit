//
//  ResultsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 12.07.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public protocol ResultsResponse: YouTubeResponse, ResultsContinuationResponse {
    /// String token that is necessary to give to the continuation request in order to make it to work (it sorts of authenticate the continuation).
    ///
    /// Only present in first ``ResultsResponse``and not in the continuations.
    var visitorData: String? { get }
}
