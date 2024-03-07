//
//  YouTubeChannel+fetchInfos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension YouTubeChannel {
    func fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<ChannelInfosResponse, Error>) -> ()) {
        ChannelInfosResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.channelId], useCookies: useCookies, result: result)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> ChannelInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<ChannelInfosResponse, Error>) in
            fetchInfos(youtubeModel: youtubeModel, useCookies: useCookies, result: { result in
                continuation.resume(with: result)
            })
        })
    }
}
