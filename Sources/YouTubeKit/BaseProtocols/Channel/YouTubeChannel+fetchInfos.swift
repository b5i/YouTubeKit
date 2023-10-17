//
//  YouTubeChannel+fetchInfos.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension YouTubeChannel {
    func fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (ChannelInfosResponse?, Error?) -> ()) {
        ChannelInfosResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.channelId], useCookies: useCookies, result: result)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchInfos(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async -> (ChannelInfosResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(ChannelInfosResponse?, Error?), Never>) in
            fetchInfos(youtubeModel: youtubeModel, useCookies: useCookies, result: { result, error in
                continuation.resume(returning: (result, error))
            })
        })
    }
}
