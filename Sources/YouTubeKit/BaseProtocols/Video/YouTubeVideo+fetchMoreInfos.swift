//
//  YouTubeVideo+fetchMoreInfos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension YouTubeVideo {
    func fetchMoreInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<MoreVideoInfosResponse, Error>) -> ()) {
        MoreVideoInfosResponse.sendRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], useCookies: useCookies, result: result)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchMoreInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> MoreVideoInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<MoreVideoInfosResponse, Error>) in
            fetchMoreInfos(youtubeModel: youtubeModel, useCookies: useCookies, result: { result in
                continuation.resume(with: result)
            })
        })
    }
}
