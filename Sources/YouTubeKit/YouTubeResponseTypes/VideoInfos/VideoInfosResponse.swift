//
//  FormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a search response.
public struct VideoInfosResponse: YouTubeResponse {
    
    public static var headersType: HeaderTypes = .videoInfos
        
    /// Name of the channel that posted the video.
    public var channel: YTLittleChannelInfos
    
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
    /// VideoInfosResponse.sendRequest(youtubeModel: YTM, data: [.query : videoId], result: { result, error in
    ///      print(result)
    ///      print(error)
    /// })
    /// ```
    public var videoId: String?
    
    
    /// Date when the video's main HLS (``VideoInfosResponse/VideoInfos-swift.struct/url``) and download formats expire.
    public var videoURLsExpireAt: Date?
    
    /// Number of view of the video, usually an integer in the string.
    public var viewCount: String?
    
    public static func decodeData(data: Data) -> VideoInfosResponse {
        let json = JSON(data)

        return decodeJSON(json)
    }
    
    /// Decode json to give an instance of ``VideoInfosResponse``.
    /// - Parameter json: the json to be decoded.
    /// - Returns: an instance of ``VideoInfosResponse``.
    public static func decodeJSON(_ json: JSON) -> VideoInfosResponse {
        /// Extract the dictionnaries that contains the video details and streaming data.
        let videoDetailsJSON = json["videoDetails"]
        let streamingJSON = json["streamingData"]
        
        return VideoInfosResponse(
            channel: YTLittleChannelInfos(
                channelId: videoDetailsJSON["channelId"].string,
                name: videoDetailsJSON["author"].string
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
                if let linksExpirationString = streamingJSON["expiresInSeconds"].string, let linksExpiration = Double(linksExpirationString) {
                    videoURLsExpireAt = Date().addingTimeInterval(linksExpiration)
                }
                return videoURLsExpireAt
            }(),
            viewCount: videoDetailsJSON["viewCount"].string
        )
    }
    
    public static func createEmpty() -> VideoInfosResponse {
        return VideoInfosResponse(channel: .init(), keywords: [], thumbnails: [])
    }
}
