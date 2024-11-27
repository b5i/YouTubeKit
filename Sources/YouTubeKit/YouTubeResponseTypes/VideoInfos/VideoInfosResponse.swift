//
//  FormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a search response.
public struct VideoInfosResponse: YouTubeResponse {
    public static let headersType: HeaderTypes = .videoInfos
    
    public static let parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    /// An array of `Caption` representing the variety of captions that the video supports
    public var captions: [YTCaption]
        
    /// Name of the channel that posted the video.
    public var channel: YTLittleChannelInfos?
    
    /// Boolean indicating if the video is livestreamed.
    public var isLive: Bool?
    
    /// Keywords attached to the video.
    public var keywords: [String]
    
    /// HLS URL of the video
    ///
    /// Can be used with a simple AVFoundation Player
    /// ```swift
    /// import SwiftUI
    /// import AVFoundation
    ///
    /// struct HLSPlayer: View
    ///     @State var queryResult: YTVideoContent
    ///
    ///     var body: some View {
    ///         AVPlayer(url: queryResult.url)
    ///     }
    /// }
    /// ```
    public var streamingURL: URL?
    
    /// Array of thumbnails.
    ///
    /// Usually sorted by resolution, from low to high.
    public var thumbnails: [YTThumbnail]
    
    /// Title of the video.
    public var title: String?
    
    /// The description of the video.
    public var videoDescription: String?
    
    /// String identifier of the video, can be used to get the formats of the video.
    ///
    /// For example:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let videoId: String = ...
    /// VideoInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.query : videoId], result: { result in
    ///      print(result)
    /// })
    /// ```
    public var videoId: String?
    
    
    /// Date when the video's main HLS (``VideoInfosResponse/streamingURL``) and download formats expire.
    public var videoURLsExpireAt: Date?
    
    /// Count of view of the video, usually an integer in the string.
    public var viewCount: String?
    
    /// The aspect ratio of the video (width/height).
    public var aspectRatio: Double?
    
    /// Array of formats used to download the video, they usually contain both audio and video data and the download speed is higher than the ``VideoInfosResponse/downloadFormats``.
    @available(*, deprecated, message: "This property is unstable for the moment.")
    public var defaultFormats: [any DownloadFormat]
    
    /// Array of formats used to download the video, usually sorted from highest video quality to lowest followed by audio formats.
    @available(*, deprecated, message: "This property is unstable for the moment.")
    public var downloadFormats: [any DownloadFormat]

    public init(
        captions: [YTCaption] = [],
        channel: YTLittleChannelInfos? = nil,
        isLive: Bool? = nil,
        keywords: [String] = [],
        streamingURL: URL? = nil,
        thumbnails: [YTThumbnail] = [],
        title: String? = nil,
        videoDescription: String? = nil,
        videoId: String? = nil,
        videoURLsExpireAt: Date? = nil,
        viewCount: String? = nil,
        aspectRatio: Double? = nil,
        defaultFormats: [any DownloadFormat] = [],
        downloadFormats: [any DownloadFormat] = []
    ) {
        self.captions = captions
        self.channel = channel
        self.isLive = isLive
        self.keywords = keywords
        self.streamingURL = streamingURL
        self.thumbnails = thumbnails
        self.title = title
        self.videoDescription = videoDescription
        self.videoId = videoId
        self.videoURLsExpireAt = videoURLsExpireAt
        self.viewCount = viewCount
        self.aspectRatio = aspectRatio
        self.defaultFormats = defaultFormats
        self.downloadFormats = downloadFormats
    }
    
    /// Decode json to give an instance of ``VideoInfosResponse``.
    /// - Parameter json: the json to be decoded.
    /// - Returns: an instance of ``VideoInfosResponse``.
    public static func decodeJSON(json: JSON) throws -> VideoInfosResponse {
        guard json["playabilityStatus"]["status"].string != "LOGIN_REQUIRED" else {
            throw ResponseExtractionError(reponseType: self.self, stepDescription: "Login is required to get access to the video streaming info.")
        }
        
        /// Extract the dictionnaries that contains the video details and streaming data.
        let videoDetailsJSON = json["videoDetails"]
        let streamingJSON = json["streamingData"]
        
        var channel: YTLittleChannelInfos? = nil
        
        if let channelId = videoDetailsJSON["channelId"].string {
            channel = YTLittleChannelInfos(channelId: channelId, name: videoDetailsJSON["author"].string)
        }
        
        return VideoInfosResponse(
            captions: {
                var captionsArray: [YTCaption] = []
                
                captionsArray.append(contentsOf: json["captions"]["playerCaptionsTracklistRenderer"]["captionTracks"].arrayValue.compactMap { captionJSON in
                    guard let url = captionJSON["baseUrl"].url else { return nil }
                    return YTCaption(languageCode: captionJSON["languageCode"].stringValue, languageName: captionJSON["name"]["simpleText"].stringValue, url: url, isTranslated: false)
                })
                
                guard let firstCaptionURL = captionsArray.first?.url else { return captionsArray }
                
                captionsArray.append(contentsOf: json["captions"]["playerCaptionsTracklistRenderer"]["translationLanguages"].arrayValue.compactMap { captionJSON in
                    return YTCaption(languageCode: captionJSON["languageCode"].stringValue, languageName: captionJSON["languageName"]["simpleText"].stringValue, url: firstCaptionURL.appending(queryItems: [.init(name: "tlang", value: captionJSON["languageCode"].stringValue)]), isTranslated: true)
                })
                
                return captionsArray
            }(),
            channel: channel,
            isLive: videoDetailsJSON["isLiveContent"].bool,
            keywords: videoDetailsJSON["keywords"].arrayObject as? [String] ?? [],
            streamingURL: streamingJSON["hlsManifestUrl"].url,
            thumbnails: {
                var thumbnails: [YTThumbnail] = []
                YTThumbnail.appendThumbnails(json: videoDetailsJSON["thumbnail"], thumbnailList: &thumbnails)
                return thumbnails
            }(),
            title: videoDetailsJSON["title"].string,
            videoDescription: videoDetailsJSON["shortDescription"].string,
            videoId: videoDetailsJSON["videoId"].string,
            videoURLsExpireAt: {
                var videoURLsExpireAt: Date? = nil
                if let linksExpirationString = streamingJSON["expiresInSeconds"].string, let linksExpiration = Double(linksExpirationString) {
                    videoURLsExpireAt = Date().addingTimeInterval(linksExpiration)
                }
                return videoURLsExpireAt
            }(),
            viewCount: videoDetailsJSON["viewCount"].string,
            aspectRatio: streamingJSON["aspectRatio"].double,
            defaultFormats: streamingJSON["formats"].arrayValue.compactMap { VideoInfosWithDownloadFormatsResponse.decodeFormatFromJSON(json: $0) },
            downloadFormats: streamingJSON["adaptiveFormats"].arrayValue.compactMap { VideoInfosWithDownloadFormatsResponse.decodeFormatFromJSON(json: $0) }
        )
    }
    
    public static func createEmpty() -> VideoInfosResponse {
        return VideoInfosResponse(keywords: [], thumbnails: [])
    }
    
    // Fix for the cookies thing
    public static func sendNonThrowingRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool? = nil,
        result: @escaping @Sendable (Result<Self, Error>) -> ()
    ) {
        /// Call YouTubeModel's `sendRequest` function to have a more readable use.
        youtubeModel.sendRequest(
            responseType: Self.self,
            data: data,
            useCookies: false,
            result: result
        )
    }
}
