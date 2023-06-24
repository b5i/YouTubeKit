//
//  YouTubeVideo+getInfosWithDownloadFormats.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YouTubeVideo {
    /// Get more infos about a video, including an array of ``DownloadFormat``.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - infos: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func getInfosWithDownloadFormats(
        youtubeModel: YouTubeModel,
        infos: @escaping (VideoInfosWithDownloadFormatsResponse?, Error?) -> ()
    ) {
        VideoInfosWithDownloadFormatsResponse.sendRequest(
            youtubeModel: youtubeModel,
            data: [.query: videoId],
            result: infos
        )
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video, including an array of ``DownloadFormats``.
    /// - Parameter youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    /// - Returns: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func getInfosWithDownloadFormats(
        youtubeModel: YouTubeModel
    ) async -> (VideoInfosWithDownloadFormatsResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(VideoInfosWithDownloadFormatsResponse?, Error?), Never>) in
            getInfosWithDownloadFormats(youtubeModel: youtubeModel, infos: { infos, error in
                continuation.resume(returning: (infos, error))
            })
        })
    }
}
