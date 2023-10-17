//
//  YouTubeVideo+fetchStreamingInfos.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YouTubeVideo {
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil,
        infos: @escaping (VideoInfosResponse?, Error?) -> ()
    ) {
        VideoInfosResponse.sendRequest(
            youtubeModel: youtubeModel,
            data: [.query: videoId],
            useCookies: useCookies,
            result: infos
        )
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil
    ) async -> (VideoInfosResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(VideoInfosResponse?, Error?), Never>) in
            fetchStreamingInfos(youtubeModel: youtubeModel, useCookies: useCookies, infos: { infos, error in
                continuation.resume(returning: (infos, error))
            })
        })
    }
}
