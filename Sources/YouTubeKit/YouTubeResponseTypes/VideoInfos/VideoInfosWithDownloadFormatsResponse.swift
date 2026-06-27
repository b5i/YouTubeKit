//
//  VideoInfosWithDownloadFormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2026 Antoine Bollengier. All rights reserved.
//

import Foundation
#if canImport(JavaScriptCore)
import JavaScriptCore
//#else
//#if os(Linux)
//import LinuxJavaScriptCore
//#endif
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Struct representing the VideoInfosWithDownloadFormatsResponse.
public struct VideoInfosWithDownloadFormatsResponse: YouTubeResponse {
    @available(*, deprecated, message: "Please use the global VideoDownloadFormat instead of VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat")
    public typealias VideoDownloadFormat = YouTubeKit.VideoDownloadFormat
    
    @available(*, deprecated, message: "Please use the global AudioOnlyFormat instead of VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat")
    public typealias AudioOnlyFormat = YouTubeKit.AudioOnlyFormat
    
    public typealias ResponseError = PlayerProcessing.Player.ResponseError
    
    public static let headersType: HeaderTypes = .videoInfosWithDownloadFormats
    
    public static let parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    /// Array of formats used to download the video, they usually contain both audio and video data and the download speed is higher than the ``VideoInfosWithDownloadFormatsResponse/downloadFormats``.
    public var defaultFormats: [any DownloadFormat]
    
    /// Array of formats used to download the video, usually sorted from highest video quality to lowest followed by audio formats.
    public var downloadFormats: [any DownloadFormat]
    
    /// Base video infos like if it did a ``VideoInfosResponse`` request.
    public var videoInfos: VideoInfosResponse
    
    /// Function that creates a ``VideoInfosWithDownloadFormatsResponse`` but that fills only the ``VideoInfosWithDownloadFormatsResponse/videoInfos`` entry and let the other propertes to nil/empty values.
    public static func decodeJSON(json: JSON) throws -> VideoInfosWithDownloadFormatsResponse {
        var toReturn = VideoInfosWithDownloadFormatsResponse(
            defaultFormats: [],
            downloadFormats: [],
            videoInfos: try VideoInfosResponse.decodeJSON(json: json)
        )
        
        toReturn.defaultFormats = toReturn.videoInfos.defaultFormats
        toReturn.downloadFormats = toReturn.videoInfos.downloadFormats

        return toReturn
    }

    
    /// Decode a ``DownloadFormat`` base informations from a JSON instance.
    /// - Parameter json: the JSON to be decoded.
    /// - Returns: A ``DownloadFormat``.
    static func decodeFormatFromJSON(json: JSON) -> DownloadFormat {
        if json["fps"].int != nil {
            /// Will return an instance of ``VideoInfosWithDownloadFormatsResponse/VideoDownloadFormat``
            return YouTubeKit.VideoDownloadFormat(
                averageBitrate: json["averageBitrate"].int,
                contentDuration: {
                    if let approxDurationMs = json["approxDurationMs"].string {
                        return Int(approxDurationMs)
                    } else {
                        return nil
                    }
                }(),
                contentLength: {
                    if let contentLength = json["contentLength"].string {
                        return Int(contentLength)
                    } else {
                        return nil
                    }
                }(),
                is360: json["projectionType"].string == "MESH",
                isCopyrightedMedia: json["signatureCipher"].string != nil,
                mimeType: json["mimeType"].string?.ytkFirstGroupMatch(for: "([^;]*)"),
                codec: json["mimeType"].string?.ytkFirstGroupMatch(for: #"codecs="([^\.]+)"#),
                url: json["signatureCipher"].string == nil ? json["url"].url : nil,
                signatureCipher: json["signatureCipher"].string,
                width: json["width"].int,
                height: json["height"].int,
                quality: json["qualityLabel"].string,
                fps: json["fps"].int
            )
        } else {
            /// Will return an instance of ``VideoInfosWithDownloadFormatsResponse/AudioOnlyFormat``
            return YouTubeKit.AudioOnlyFormat(
                averageBitrate: json["averageBitrate"].int,
                contentLength: {
                    if let contentLength = json["contentLength"].string {
                        return Int(contentLength)
                    } else {
                        return nil
                    }
                }(),
                contentDuration: {
                    if let approxDurationMs = json["approxDurationMs"].string {
                        return Int(approxDurationMs)
                    } else {
                        return nil
                    }
                }(),
                isCopyrightedMedia: json["signatureCipher"].string != nil,
                url: json["signatureCipher"].string == nil ? json["url"].url : nil,
                signatureCipher: json["signatureCipher"].string,
                mimeType: json["mimeType"].string?.ytkFirstGroupMatch(for: "([^;]*)"),
                codec: json["mimeType"].string?.ytkFirstGroupMatch(for: #"codecs="([^\.]+)"#),
                audioSampleRate: {
                    if let audioSampleRate = json["audioSampleRate"].string {
                        return Int(audioSampleRate)
                    } else {
                        return nil
                    }
                }(),
                loudness: json["loudnessDb"].double,
                formatLocaleInfos: json["audioTrack", "id"].string != nil ? .init(displayName: json["audioTrack", "displayName"].string, localeId: json["audioTrack", "id"].string, isDefaultAudioFormat: json["audioTrack", "audioIsDefault"].bool, isAutoDubbed: json["audioTrack", "isAutoDubbed"].bool) : nil
            )
        }
    }
    
    @available(*, deprecated, renamed: "PlayerProcessing.PlayersCache.clearCache")
    public static func removePlayersCache() throws {
        try PlayerProcessing.PlayersCache.clearCache()
    }
    
    public mutating func deciphersURLs(player: PlayerProcessing.Player) throws {
        try self.downloadFormats.inoutMap { item in
            try player.processDownloadFormatURL(item: &item)
        }
        
        try self.defaultFormats.inoutMap { item in
            try player.processDownloadFormatURL(item: &item)
        }
    }
}
