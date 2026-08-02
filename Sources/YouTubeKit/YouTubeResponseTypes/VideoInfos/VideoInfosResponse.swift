//
//  FormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2026 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing the streaming info of a video.
public struct VideoInfosResponse: YouTubeResponse {
    /// WEB client values returned by the watch page for the current request.
    public struct Client: Sendable {
        public let name: String

        /// Numeric form of ``name`` used by YouTube's binary protocols.
        public let numericID: Int
        public let version: String
        public let osName: String
        public let osVersion: String
        public let userAgent: String
    }

    public static let headersType: HeaderTypes = .videoInfos
    
    public static let parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    public typealias ResponseError = PlayerProcessing.Player.ResponseError
    
    /// An array of `Caption` representing the variety of captions that the video supports
    public var captions: [YTCaption]

    /// "Storyboard" data of the video, is used to get the preview image when seeking through the video.
    public var storyboard: YTStoryboard?

    /// Server-driven adaptive streaming fields used by native media clients.
    public var serverAbrStreamingURL: URL?

    /// Base64url-encoded uStreamer configuration returned by the player response.
    ///
    /// Native SABR clients decode this value and copy the resulting, server-defined bytes unchanged, in the stream request. Content of the payload is opaque.
    public var videoPlaybackUstreamerConfig: String?
    public var visitorData: String?
    public var minimumReadAheadMediaTimeMs: Int?

    /// Client identity selected by YouTube for the watch-page request.
    public var client: Client?
        
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
    ///
    /// - Note: when putting this URL in an `AVURLAsset` to play it on macOS, you need to remove any potential VP9-format video from it, for example using a custom `AVAssetResourceLoaderDelegate`.
    /// - Note: to see whether the stream is 360°, you can check if the `YT-EXT-PROJECTION-TYPE="equirectangular"` parameter is set in the .m3u8 playlist.
    /// - Note: in some cases, you might have an HLS file with multiple video streams, each having a different audio language, making it not compliant to the HLS standard (video and audio should be separated to allow easy language selection without having a new video flux).
    /// This causes Apple's `AVPlayer` to play the first video flux in the file which has probably not the language you want to play the video in.
    /// In this case, you can use a custom `AVAssetResourceLoaderDelegate` to filter the video streams you don't want to be played. Note that the default language of the video can be obtained using
    /// ```swift
    /// self.downloadFormats
    ///     .compactMap {
    ///         $0 as? AudioOnlyFormat
    ///     }
    ///     .first(where: { $0.formatLocaleInfos?.isDefaultAudioFormat == true })?
    ///     .formatLocaleInfos?.localeId
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
    
    /// Endscreen of the video.
    public var endScreen: EndScreen? = nil
    
    /// The aspect ratio of the video (width/height).
    public var aspectRatio: Double?
    
    /// The start time of the video in seconds, represents the time that was already partially watched or that the "t" parameter is set in the video URL. Currently disabled because we can't make VideoInfosResponse requests with cookies.
    ///
    /// - Note: This property is also available on ``YTVideo/startTime``, please use this value.
    //public var startTime: Int? = nil
    
    /// Array of formats used to download the video, they usually contain both audio and video data and the download speed is higher than the ``VideoInfosResponse/downloadFormats``.
    ///
    /// - Note: Those formats usually don't contain a valid URL, but only their metadata. Use a ``VideoInfosWithDownloadFormatsResponse`` and call ``VideoInfosWithDownloadFormatsResponse/deciphersURLs(player:)`` with the ``PlayerProcessing/Player`` instance of this `VideoInfosResponse` to get the download URLs of those formats.
    //@available(*, deprecated, message: "This property is unstable for the moment.")
    public var defaultFormats: [any AdaptiveDownloadFormat]
    
    /// Array of formats used to download the video, usually sorted from highest video quality to lowest followed by audio formats.
    //@available(*, deprecated, message: "This property is unstable for the moment.")
    public var downloadFormats: [any AdaptiveDownloadFormat]
    
    public var player: PlayerProcessing.Player?

    public init(
        captions: [YTCaption] = [],
        storyboard: YTStoryboard? = nil,
        serverAbrStreamingURL: URL? = nil,
        videoPlaybackUstreamerConfig: String? = nil,
        visitorData: String? = nil,
        minimumReadAheadMediaTimeMs: Int? = nil,
        client: Client? = nil,
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
        endScreen: EndScreen? = nil,
        //startTime: Int? = nil,
        defaultFormats: [any AdaptiveDownloadFormat] = [],
        downloadFormats: [any AdaptiveDownloadFormat] = [],
        player: PlayerProcessing.Player? = nil
    ) {
        self.captions = captions
        self.storyboard = storyboard
        self.serverAbrStreamingURL = serverAbrStreamingURL
        self.videoPlaybackUstreamerConfig = videoPlaybackUstreamerConfig
        self.visitorData = visitorData
        self.minimumReadAheadMediaTimeMs = minimumReadAheadMediaTimeMs
        self.client = client
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
        self.endScreen = endScreen
        //self.startTime = startTime
        self.defaultFormats = defaultFormats
        self.downloadFormats = downloadFormats
        self.player = player
    }
    
    // Overwrite the data processing
    public static func decodeData(data: Data) throws -> VideoInfosResponse {
        /// Special processing for VideoInfosWithDownloadFormatsResponse
        
        /// The received data is not some JSON, it is an HTML file containing the JSON and other relevant informations that are necessary to process the ``DownloadFormat``.
        /// It begins by getting the player version (the player is a JS script used to manage the player on their webpage and it decodes the n-parameter).
        
        let html = String(decoding: data, as: UTF8.self)
        
        /// We have something like this ** /s/player/playerId/player_ias.vflset/en_US/base.js **
        guard let path = html.ytkFirstGroupMatch(for: #"<link as=\"script\" rel=\"preload\" href=\"([^\"]+/base\.js)\""#) ?? html.ytkFirstGroupMatch(for: #"(?:PLAYER_JS_URL|jsUrl)\\?"?\s*[:=]\s*\\?"([^"\\]+/base\.js)"#)
        else {
            throw ResponseError(step: .decodeData, reason: "Couldn't get player path.")
        }
        guard let responseData = html.ytkFirstSubstringBetween(prefix: "var ytInitialPlayerResponse = ", suffix: ";</script><div id=\"player\"")
        else {
            throw ResponseError(step: .decodeData, reason: "Couldn't get player JSON.")
        }

        let player = try PlayerProcessing.Player.getPlayer(forPath: path)
        var response = try decodeJSON(json: JSON(parseJSON: responseData))
        response.player = player
        let watchConfiguration = try decodeWatchConfiguration(in: html)
        response.client = watchConfiguration.client
        if response.visitorData == nil {
            response.visitorData = watchConfiguration.visitorData
        }
        
        // The n-parameter in HLS manifest URLs is embedded as a path segment "/n/VALUE/" rather than as a query parameter, so it needs its own handling.
        if let hlsManifestURLString = response.streamingURL?.absoluteString {
            response.streamingURL = player.decodeNParameterInHLSManifestURL(
                hlsManifestURLString
            )
        }
        return response
    }
    
    /// Decode json to give an instance of ``VideoInfosResponse``.
    /// - Parameter json: the json to be decoded.
    /// - Returns: an instance of ``VideoInfosResponse``.
    public static func decodeJSON(json: JSON) throws -> VideoInfosResponse {
        guard json["playabilityStatus", "status"].string != "LOGIN_REQUIRED" else {
            throw ResponseExtractionError(reponseType: self.self, stepDescription: "Login is required to get access to the video streaming info.")
        }
        guard json["playabilityStatus", "status"].string != "UNPLAYABLE" else {
            throw ResponseExtractionError(reponseType: self.self, stepDescription: json["playabilityStatus", "reason"].string ?? "Unkown error")
        }
        
        /// Extract the dictionnaries that contains the video details and streaming data.
        let videoDetailsJSON = json["videoDetails"]
        let streamingJSON = json["streamingData"]
        
        var channel: YTLittleChannelInfos? = nil
        
        if let channelId = videoDetailsJSON["channelId"].string {
            channel = YTLittleChannelInfos(channelId: channelId, name: videoDetailsJSON["author"].string)
        }
        
        let endScreenRenderer = json["endscreen", "endscreenRenderer"]
        
        return VideoInfosResponse(
            captions: decodeCaptions(json),
            storyboard: decodeStoryboard(json),
            serverAbrStreamingURL: streamingJSON["serverAbrStreamingUrl"].url,
            videoPlaybackUstreamerConfig: json["playerConfig", "mediaCommonConfig", "mediaUstreamerRequestConfig", "videoPlaybackUstreamerConfig"].string,
            visitorData: json["responseContext", "visitorData"].string,
            minimumReadAheadMediaTimeMs: json["playerConfig", "mediaCommonConfig", "dynamicReadaheadConfig", "minReadAheadMediaTimeMs"].int,
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
            endScreen: EndScreen(
                startTime: Int(endScreenRenderer["startMs"].stringValue),
                elements: endScreenRenderer["elements"].arrayValue.compactMap {
                    $0["endscreenElementRenderer"].exists() ? EndScreenElement(fromEndscreenElementRenderer: $0["endscreenElementRenderer"]) : nil
            }),
            //startTime: json["playerConfig", "playbackStartConfig", "startSeconds"].int,
            defaultFormats: streamingJSON["formats"].arrayValue.compactMap { VideoInfosWithDownloadFormatsResponse.decodeFormatFromJSON(json: $0) },
            downloadFormats: streamingJSON["adaptiveFormats"].arrayValue.compactMap { VideoInfosWithDownloadFormatsResponse.decodeFormatFromJSON(json: $0) }
        )
    }

    private static func decodeCaptions(_ json: JSON) -> [YTCaption] {
        let tracks = json["captions", "playerCaptionsTracklistRenderer", "captionTracks"].arrayValue
        var translationSource: YTCaption?
        var captions = tracks.enumerated().compactMap { index, track -> YTCaption? in
            guard let url = track["baseUrl"].url else { return nil }
            let code = track["languageCode"].stringValue
            let name = track["name", "simpleText"].string ?? track["name", "runs"].arrayValue.map {
                $0["text"].stringValue
            }.joined()
            let caption = YTCaption(
                languageCode: code,
                languageName: name.isEmpty ? code : name,
                url: url,
                isTranslated: false,
                id: "source:\(track["vssId"].string ?? code):\(index)",
                isAutoGenerated: track["kind"].string == "asr"
            )
            if translationSource == nil, track["isTranslatable"].boolValue {
                translationSource = caption
            }
            return caption
        }

        guard let source = translationSource else { return captions }
        let sourceCodes = Set(captions.map(\.languageCode))
        captions += json["captions", "playerCaptionsTracklistRenderer", "translationLanguages"]
            .arrayValue.compactMap { language in
                let code = language["languageCode"].stringValue
                guard !sourceCodes.contains(code) else { return nil }
                let name = language["languageName", "simpleText"].string
                ?? language["languageName", "runs"].arrayValue.map {
                    $0["text"].stringValue
                }.joined()
                return YTCaption(
                    languageCode: code,
                    languageName: name.isEmpty ? code : name,
                    url: source.url.appending(queryItems: [
                        URLQueryItem(name: "tlang", value: code)
                    ]),
                    isTranslated: true,
                    id: "translated:\(source.id):\(code)",
                    isAutoGenerated: source.isAutoGenerated
                )
            }
        return captions
    }

    private static func decodeStoryboard(_ json: JSON) -> YTStoryboard? {
        let renderer = json["storyboards", "playerStoryboardSpecRenderer"]
        guard let spec = renderer["spec"].string else { return nil }
        return YTStoryboard(
            spec: spec,
            recommendedLevel: renderer["recommendedLevel"].int
        )
    }

    static func decodeWatchConfiguration(
        in html: String
    ) throws -> (client: Client, visitorData: String?) {
        let values = jsonObjects(after: "ytcfg.set(", in: html).compactMap {
            try? JSON(data: $0)
        }
        let clientValues = values
            .map { $0["INNERTUBE_CONTEXT", "client"] }
            .first(where: { $0.exists() })
        guard let clientValues,
              let name = clientValues["clientName"].string,
              let version = clientValues["clientVersion"].string,
              let osName = clientValues["osName"].string,
              let osVersion = clientValues["osVersion"].string,
              var userAgent = clientValues["userAgent"].string,
              let numericID = values.compactMap({
                  $0["INNERTUBE_CONTEXT_CLIENT_NAME"].int
              }).first
        else {
            throw ResponseError(
                step: .decodeData,
                reason: "Couldn't get watch client configuration."
            )
        }
        if userAgent.hasSuffix(",gzip(gfe)") {
            userAgent.removeLast(",gzip(gfe)".count)
        }
        return (
            client: Client(
                name: name,
                numericID: numericID,
                version: version,
                osName: osName,
                osVersion: osVersion,
                userAgent: userAgent
            ),
            visitorData: clientValues["visitorData"].string
        )
    }

    private static func jsonObjects(after marker: String, in text: String) -> [Data] {
        var result: [Data] = []
        var searchStart = text.startIndex
        while let markerRange = text.range(
            of: marker,
            range: searchStart..<text.endIndex
        ) {
            guard let object = jsonObject(
                startingAfter: markerRange.upperBound,
                in: text
            ) else {
                searchStart = markerRange.upperBound
                continue
            }
            result.append(Data(text[object.range].utf8))
            searchStart = object.end
        }
        return result
    }

    private static func jsonObject(
        startingAfter start: String.Index,
        in text: String
    ) -> (range: Range<String.Index>, end: String.Index)? {
        var cursor = start
        while cursor < text.endIndex, text[cursor].isWhitespace {
            cursor = text.index(after: cursor)
        }
        guard cursor < text.endIndex, text[cursor] == "{" else { return nil }

        let objectStart = cursor
        var depth = 0
        var inString = false
        var escaped = false
        while cursor < text.endIndex {
            let character = text[cursor]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else if character == "\"" {
                inString = true
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    let end = text.index(after: cursor)
                    return (objectStart..<end, end)
                }
            }
            cursor = text.index(after: cursor)
        }
        return nil
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
