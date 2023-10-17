//
//  YouTubeVideo.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Protocol used to identify all struct that can be apparented to videos from YouTube.
public protocol YouTubeVideo {
    
    /// String identifier of the video, can be used to get the infos of the video.
    ///
    /// For example:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let videoId: String = ...
    /// VideoInfosResponse.sendRequest(youtubeModel: YTM, data: [.query : videoId], result: { result, error in
    ///      print(result)
    ///      print(error)
    /// })
    /// ```
    ///
    /// Or even simpler, use the built-in `getInfos()` method
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let video: some YouTubeVideo = ...
    /// video.getInfos(youtubeModel: YTM, infos: { result, error in
    ///     print(result)
    ///     print(error)
    /// })
    /// ```
    var videoId: String { get set }
    
    /// Video's title.
    var title: String? { get set }
    
    /// Channel informations.
    var channel: YTLittleChannelInfos? { get set }
    
    /// Count of views of the video, in a shortened string.
    var viewCount: String? { get set }
    
    /// String representing the moment when the video was posted.
    ///
    /// Usually like `posted 3 months ago`.
    var timePosted: String? { get set }
    
    /// String representing the duration of the video.
    ///
    /// Can be `live` instead of `ab:cd` if the video is a livestream.
    var timeLength: String? { get set }
    
    /// Array of thumbnails.
    ///
    /// Usually sorted by resolution, from low to high.
    var thumbnails: [YTThumbnail] { get set }
    
    /// Get more infos about a video.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - infos: A ``VideoInfosResponse`` or an error.
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        infos: @escaping (VideoInfosResponse?, Error?) -> ()
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``VideoInfosResponse`` or an error.
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async -> (VideoInfosResponse?, Error?)
    
    /// Get more infos about a video, including an array of ``DownloadFormat``.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - infos: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func fetchStreamingInfosWithDownloadFormats(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        infos: @escaping (VideoInfosWithDownloadFormatsResponse?, Error?) -> ()
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video, including an array of ``DownloadFormats``.
    /// - Parameters:
    ///    - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///    - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func fetchStreamingInfosWithDownloadFormats(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async -> (VideoInfosWithDownloadFormatsResponse?, Error?)
    
    /// Get more informations about a video (detailled description, chapters, recommended videos, etc...).
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Parameter result: the closure to execute when the request is finished.
    func fetchMoreInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        result: @escaping (MoreVideoInfosResponse?, Error?) -> ()
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more informations about a video (detailled description, chapters, recommended videos, etc...).
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``MoreVideoInfosResponse`` or an error.
    func fetchMoreInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async -> (MoreVideoInfosResponse?, Error?)
    
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func likeVideo(
        youtubeModel: YouTubeModel,
        result: @escaping (Error?) -> Void
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func likeVideo(youtubeModel: YouTubeModel) async -> Error?
    
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func dislikeVideo(
        youtubeModel: YouTubeModel,
        result: @escaping (Error?) -> Void
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func dislikeVideo(youtubeModel: YouTubeModel) async -> Error?
    
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeLikeFromVideo(
        youtubeModel: YouTubeModel,
        result: @escaping (Error?) -> Void
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeLikeFromVideo(youtubeModel: YouTubeModel) async -> Error?
}
