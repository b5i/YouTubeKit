//
//  VideoInfosWithDownloadFormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public struct VideoInfosWithDownloadFormatsResponse: YouTubeResponse {
    public static var headersType: HeaderTypes = .videoInfosWithDownloadFormats
    
    /// Array of formats used to download the video, usually sorted from highest video quality to lowest followed by audio formats.
    public var downloadFormats: [any DownloadFormat]
    
    /// Base video infos like if it did a ``VideoInfosResponse`` request.
    public var videoInfos: VideoInfosResponse
    
    public static func decodeData(data: Data) -> VideoInfosWithDownloadFormatsResponse {
        /// The received data is not some JSON, it is an HTML file containing the JSON and other relevant informations that are necessary to process the ``DownloadFormat``.
        /// It begins by getting the player version (the player is a JS script used to manage the player on their webpage and it decodes the n-parameter).
        let dataToString = String(decoding: data, as: UTF8.self)
        
        //guard dataToString.components(separatedBy: "<link rel=\"preload\" href=\"https://i.ytimg.com/generate_204\" as=\"fetch\"><link as=\"script\" rel=\"preload\" href=\"\"").count > 1 else { return }
        
        let json = JSON(data)
        
        /// Extract the dictionnaries that contains the video details and streaming data.
        let videoDetailsJSON = json["videoDetails"]
        let streamingJSON = json["streamingData"]
        
        return VideoInfosWithDownloadFormatsResponse(
            downloadFormats: [],
            videoInfos:
                VideoInfosResponse(
                    channel: YTLittleChannelInfos(
                        name: videoDetailsJSON["author"].string,
                        browseId: videoDetailsJSON["channelId"].string
                    ),
                    isLive: videoDetailsJSON["isLiveContent"].bool,
                    keywords: videoDetailsJSON["keywords"].arrayObject as? [String] ?? [],
                    streamingURL: streamingJSON["hlsManifestUrl"].url,
                    thumbnails: {
                        var thumbnails: [YTThumbnail] = []
                        YTThumbnail.appendThumbnails(json: videoDetailsJSON, thumbnailList: &thumbnails)
                        return thumbnails
                    }(),
                    title: videoDetailsJSON["title"].string,
                    videoDescription: videoDetailsJSON["shortDescription"].string,
                    videoId: videoDetailsJSON["videoId"].string,
                    videoURLsExpireAt: {
                        var videoURLsExpireAt: Date? = nil
                        if let linksExpiration = streamingJSON["expiresInSeconds"].double {
                            videoURLsExpireAt = Date().addingTimeInterval(linksExpiration)
                        }
                        return videoURLsExpireAt
                    }(),
                    viewCount: videoDetailsJSON["viewCount"].string
                )
        )
    }
    
    /// Struct representing a download format that contains the video and audio.
    public struct VideoDownloadFormat: DownloadFormat {
        /// Protocol properties
        public static let type: MediaType = .video
        
        public var averageBitrate: Int
        
        public var contentDuration: Int
        
        public var contentLength: Int
        
        public var isCopyrightedMedia: Bool
        
        public var url: URL
        
        /// Video-specific infos
        
        /// Width in pixels of the media.
        public var width: Int
        
        /// Height in pixels of the media.
        public var height: Int
        
        /// Quality label of the media
        ///
        /// For example:
        /// - **720p**
        /// - **480p**
        /// - **360p**
        public var quality: String
        
        /// Frames per second of the media.
        public var fps: Int
    }
    
    public struct AudioOnlyFormat: DownloadFormat {
        /// Protocol properties
        public static let type: MediaType = .audio
        
        public var averageBitrate: Int
        
        public var contentLength: Int
        
        public var contentDuration: Int
        
        public var isCopyrightedMedia: Bool
        
        public var url: URL
        
        /// Audio only medias specific infos
        
        /// Sample rate of the audio in hertz.
        public var audioSampleRate: Int
        
        /// Audio loudness in decibels.
        public var loudness: Double
    }
}
