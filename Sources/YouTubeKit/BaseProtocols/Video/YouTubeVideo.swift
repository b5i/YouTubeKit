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
    var channel: YTLittleChannelInfos { get set }
    
    /// Number of views of the video, in a shortened string.
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
    func getInfos(
        youtubeModel: YouTubeModel,
        infos: @escaping (VideoInfosResponse?, Error?) -> ()
    )
    
    /// Get more infos about a video, including an array of ``DownloadFormat``.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    ///   - infos: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func getInfosWithDownloadFormats(
        youtubeModel: YouTubeModel,
        infos: @escaping (VideoInfosWithDownloadFormatsResponse?, Error?) -> ()
    )
    
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video.
    /// - Parameter youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    /// - Returns: A ``VideoInfosResponse`` or an error.
    func getInfos(
        youtubeModel: YouTubeModel
    ) async -> (VideoInfosResponse?, Error?)
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get more infos about a video, including an array of ``DownloadFormats``.
    /// - Parameter youtubeModel: the ``YouTubeModel`` that has to be used to know which headers to use.
    /// - Returns: A ``VideoInfosWithDownloadFormatsResponse`` or an error.
    func getInfosWithDownloadFormats(
        youtubeModel: YouTubeModel
    ) async -> (VideoInfosWithDownloadFormatsResponse?, Error?)
}
