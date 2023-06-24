//
//  YouTubeVideo+getInfos.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YouTubeVideo {
    /// Get more infos about a video.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - infos: A ``VideoInfosResponse`` or an error.
    func getInfos(
        youtubeModel: YouTubeModel,
        infos: @escaping (VideoInfosResponse?, Error?) -> ()
    ) {
        VideoInfosResponse.sendRequest(
            youtubeModel: youtubeModel,
            data: [.query: videoId],
            result: infos
        )
    }
    
    /// Get more infos about a video.
    /// - Parameter youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    /// - Returns: A ``VideoInfosResponse`` or an error.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func getInfos(
        youtubeModel: YouTubeModel
    ) async -> (VideoInfosResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(VideoInfosResponse?, Error?), Never>) in
            getInfos(youtubeModel: youtubeModel, infos: { infos, error in
                continuation.resume(returning: (infos, error))
            })
        })
    }
}
