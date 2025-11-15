//
//  DownloadFormat.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Protocol representing a particular video/audio format that can be downloaded.
public protocol DownloadFormat: Sendable {
    /// Type of the format.
    static var type: MediaType { get }
    
    /// Average birate of the media.
    var averageBitrate: Int? { get }
    
    /// Content length of the media, in bytes.
    var contentLength: Int? { get }
    
    /// Duration of the media in milliseconds.
    var contentDuration: Int? { get }
    
    /// Boolean indicating if the media is protected by YouTube from downloading.
    ///
    /// **Warning**:
    /// This property doesn't tell you if the media is copyright-free!
    var isCopyrightedMedia: Bool? { get }
    
    /// Download URL of the format.
    var url: URL? { get set }
    
    /// The mimeType of the format.
    ///
    /// Is usually "video/mp4", "video/webm", "audio/mp4" or "audio/webm".
    /// - Note: The WebM (mimeType: "audio/webm" or "video/webm") format isn't supported natively by AVFoundation.
    var mimeType: String? { get set }
    
    /// The codec of the format.
    ///
    /// It can be "avc1", "mp4a" or "av01" for example.
    /// - Note: The AV1 codec (codec: "av01") isn't supported natively by AVFoundation (for the moment) if you use it with an `AVMutableComposition`.
    var codec: String? { get set }
}
