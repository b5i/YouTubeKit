//
//  ResultsContinuationResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 12.07.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public protocol ResultsContinuationResponse: YouTubeResponse {
    /// Continuation token used to fetch more results, nil if there is no more results to fetch.
    var continuationToken: String? { get }
    
    /// Results of the continuation search.
    var results: [any YTSearchResult] { get set }
}
