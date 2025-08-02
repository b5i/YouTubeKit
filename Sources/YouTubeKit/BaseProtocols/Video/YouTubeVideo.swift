//
//  YouTubeVideo.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
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
    /// VideoInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.query : videoId], result: { result in
    ///      print(result)
    /// })
    /// ```
    ///
    /// Or even simpler, use the built-in `fetchStreamingInfos()` method
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let video: some YouTubeVideo = ...
    /// video.fetchStreamingInfos(youtubeModel: YTM, infos: { result in
    ///     print(result)
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
    /// - Warning: For some reason, making this request using cookies will fail, therefore cookies are disabled when doing the request. Private videos will unfortunately not be accessible.
    func fetchStreamingInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        infos: @escaping @Sendable (Result<VideoInfosResponse, Error>) -> ()
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``VideoInfosResponse`` or an error.
    /// - Warning: For some reason, making this request using cookies will fail, therefore cookies are disabled when doing the request. Private videos will unfortunately not be accessible.
    func fetchStreamingInfosThrowing(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async throws -> VideoInfosResponse
    
    /// Get more infos about a video, including an array of ``DownloadFormat``.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - infos: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func fetchStreamingInfosWithDownloadFormats(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        infos: @escaping @Sendable (Result<VideoInfosWithDownloadFormatsResponse, Error>) -> ()
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video, including an array of ``DownloadFormats``.
    /// - Parameters:
    ///    - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///    - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func fetchStreamingInfosWithDownloadFormatsThrowing(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async throws -> VideoInfosWithDownloadFormatsResponse
    
    /// Get more informations about a video (detailled description, chapters, recommended videos, etc...).
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Parameter result: the closure to execute when the request is finished.
    func fetchMoreInfos(
        youtubeModel: YouTubeModel,
        useCookies: Bool?,
        result: @escaping @Sendable (Result<MoreVideoInfosResponse, Error>) -> ()
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more informations about a video (detailled description, chapters, recommended videos, etc...).
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: A ``MoreVideoInfosResponse`` or an error.
    func fetchMoreInfosThrowing(
        youtubeModel: YouTubeModel,
        useCookies: Bool?
    ) async throws -> MoreVideoInfosResponse
    
    /// Get all the user's playlists and if the video is already inside or not.
    func fetchAllPossibleHostPlaylists(
        youtubeModel: YouTubeModel,
        result: @escaping @Sendable (Result<AllPossibleHostPlaylistsResponse, Error>) -> Void
    )
    
    /// Get all the user's playlists and if the video is already inside or not.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fetchAllPossibleHostPlaylistsThrowing(youtubeModel: YouTubeModel) async throws -> AllPossibleHostPlaylistsResponse
    
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func likeVideo(
        youtubeModel: YouTubeModel,
        result: @escaping @Sendable (Error?) -> Void
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func likeVideoThrowing(youtubeModel: YouTubeModel) async throws
    
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
        result: @escaping @Sendable (Error?) -> Void
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func dislikeVideoThrowing(youtubeModel: YouTubeModel) async throws
    
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
        result: @escaping @Sendable (Error?) -> Void
    )
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeLikeFromVideoThrowing(youtubeModel: YouTubeModel) async throws
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeLikeFromVideo(youtubeModel: YouTubeModel) async -> Error?
    
    /// Get the captions for the current video.
    static func getCaptions(youtubeModel: YouTubeModel, captionType: YTCaption, result: @escaping @Sendable (Result<VideoCaptionsResponse, Error>) -> Void)
    
    /// Get the captions for the current video.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func getCaptionsThrowing(youtubeModel: YouTubeModel, captionType: YTCaption) async throws -> VideoCaptionsResponse
    
    /// Get the captions for the current video.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func getCaptions(youtubeModel: YouTubeModel, captionType: YTCaption) async -> Result<VideoCaptionsResponse, Error>
}
