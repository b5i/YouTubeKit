//
//  YouTubeChannel.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public protocol YouTubeChannel {
    /// Channel's identifier, can be used to get the informations about the channel.
    ///
    /// For example:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let channelId: String = ...
    /// ChannelInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.browseId : channelId], result: { result in
    ///      print(result)
    /// })
    /// ```
    var channelId: String { get set }
    
    /// Name of the owning channel.
    var name: String? { get set }
    
    /// Array of thumbnails representing the avatar of the channel.
    ///
    /// Usually sorted by resolution from low to high.
    /// Only found in ``YTVideo``items in ``SearchResponse`` and ``HomeScreenResponse`` and their continuation.
    var thumbnails: [YTThumbnail] { get set }
    
    /// Get more informations about a channel (homepage infos of the channel ``ChannelInfosResponse``)
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Parameter result: the closure to execute when the request is finished.
    func fetchInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        result: @escaping @Sendable (Result<ChannelInfosResponse, Error>) -> ()
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more informations about a video (detailled description, chapters, recommended videos, etc...).
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``MoreVideoInfosResponse`` or an error.
    func fetchInfosThrowing(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async throws -> ChannelInfosResponse
}
