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
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - infos: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func getInfosWithDownloadFormats(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil,
        infos: @escaping (VideoInfosWithDownloadFormatsResponse?, Error?) -> ()
    ) {
        VideoInfosWithDownloadFormatsResponse.sendRequest(
            youtubeModel: youtubeModel,
            data: [.query: videoId],
            useCookies: useCookies,
            result: infos
        )
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video, including an array of ``DownloadFormats``.
    /// - Parameters:
    ///    - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///    - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func getInfosWithDownloadFormats(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil
    ) async -> (VideoInfosWithDownloadFormatsResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(VideoInfosWithDownloadFormatsResponse?, Error?), Never>) in
            getInfosWithDownloadFormats(youtubeModel: youtubeModel, useCookies: useCookies, infos: { infos, error in
                continuation.resume(returning: (infos, error))
            })
        })
    }
}
