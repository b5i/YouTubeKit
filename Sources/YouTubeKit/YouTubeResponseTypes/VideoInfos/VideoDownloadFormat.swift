//
//  VideoDownloadFormat.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 02.08.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation

/// Struct representing a download format that contains the video and audio.
public struct VideoDownloadFormat: DownloadFormat {
    public init(averageBitrate: Int? = nil, contentDuration: Int? = nil, contentLength: Int? = nil, is360: Bool? = nil, isCopyrightedMedia: Bool? = nil, mimeType: String? = nil, codec: String? = nil, url: URL? = nil, width: Int? = nil, height: Int? = nil, quality: String? = nil, fps: Int? = nil) {
        self.averageBitrate = averageBitrate
        self.contentDuration = contentDuration
        self.contentLength = contentLength
        self.is360 = is360
        self.isCopyrightedMedia = isCopyrightedMedia
        self.mimeType = mimeType
        self.codec = codec
        self.url = url
        self.width = width
        self.height = height
        self.quality = quality
        self.fps = fps
    }
    
    /// Protocol properties
    public static let type: MediaType = .video
    
    public var averageBitrate: Int?
    
    public var contentDuration: Int?
    
    public var contentLength: Int?
    
    public var is360: Bool?
    
    public var isCopyrightedMedia: Bool?
    
    public var mimeType: String?
    
    public var codec: String?
    
    public var url: URL?
    
    /// Video-specific infos
    
    /// Width in pixels of the media.
    public var width: Int?
    
    /// Height in pixels of the media.
    public var height: Int?
    
    /// Quality label of the media
    ///
    /// For example:
    /// - **720p**
    /// - **480p**
    /// - **360p**
    public var quality: String?
    
    /// Frames per second of the media.
    public var fps: Int?
}
