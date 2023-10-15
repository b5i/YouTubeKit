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
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - infos: A ``VideoInfosResponse`` or an error.
    func getInfos(
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
    
    /// Get more infos about a video.
    /// - Parameters:
    ///    - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///    - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``VideoInfosResponse`` or an error.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func getInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil
    ) async -> (VideoInfosResponse?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(VideoInfosResponse?, Error?), Never>) in
            getInfos(youtubeModel: youtubeModel, useCookies: useCookies, infos: { infos, error in
                continuation.resume(returning: (infos, error))
            })
        })
    }
}
