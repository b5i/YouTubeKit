//
//  ResultsResponse+fetchContinuation.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension ResultsResponse {
    func fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping ((Continuation)?, Error?) -> Void) {
        if let continuationToken = continuationToken {
            if let visitorData = visitorData {
                Continuation.sendRequest(youtubeModel: youtubeModel, data: [.continuation: continuationToken, .visitorData: visitorData], useCookies: useCookies, result: result)
            } else {
                Continuation.sendRequest(youtubeModel: youtubeModel, data: [.continuation: continuationToken], useCookies: useCookies, result: result)
            }
        } else {
            result(nil, "Continuation token is not defined.")
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> ((Continuation)?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(Continuation?, Error?), Never>) in
            fetchContinuation(youtubeModel: youtubeModel, useCookies: useCookies, result: { response, error in
                continuation.resume(returning: (response, error))
            })
        })
    }
}
