//
//  DownloadFormat.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2026 Antoine Bollengier. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "AdaptiveDownloadFormat")
public typealias DownloadFormat = AdaptiveDownloadFormat

/// Protocol representing audio/video only formats that can be muxed together with another format to create a playable video.
public protocol AdaptiveDownloadFormat: Sendable {
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
    
    /// Download URL of the format, may need ``PlayerProcessing/Player/processDownloadFormatURL(item:)`` in order to work.
    var url: URL? { get set }
    
    /// A cipher containing the ciphered URL of the format, need to be deciphered using ``PlayerProcessing/Player/processDownloadFormatURL(item:)``.
    var signatureCipher: String? { get set }
    
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
    
    /// YouTube's internal format identifier ("itag") for this format.
    /// Each itag corresponds to a fixed combination of container, codec,
    /// resolution, and audio bitrate/channel layout (e.g. itag 137 is
    /// 1080p H.264 video-only MP4, itag 140 is 128kbps AAC audio-only
    /// M4A).
    var itag: Int { get set }

    /// Bitrate in bits per second.
    var bitrate: Int? { get set }

    /// Last generation/transcoding of the format, in microseconds.
    var lastModified: UInt64 { get set }

    /// Non-documented string attached to some formats.
    var xtags: String { get set }

    /// Frame width in pixels. `nil` for audio-only adaptive formats.
    var width: Int? { get set }

    /// Frame height in pixels. `nil` for audio-only adaptive formats.
    var height: Int? { get set }

    /// Boolean indicating whether Dynamic Range Compression is
    /// applied. Always
    /// `false`/irrelevant for video-only formats.
    var isDrc: Bool { get set }
}

/// Audio/video only format that can be muxed together with another format to create a playable video.
/// - Note: a ``DownloadFormat`` is actually a ``AdaptiveDownloadFormat``, for compatiblity
public extension AdaptiveDownloadFormat {

    /// YouTube's internal format identifier ("itag") for this format.
    /// Each itag corresponds to a fixed combination of container, codec,
    /// resolution, and audio bitrate/channel layout (e.g. itag 137 is
    /// 1080p H.264 video-only MP4, itag 140 is 128kbps AAC audio-only
    /// M4A).
    var itag: Int { -1 }

    /// Bitrate in bits per second.
    var bitrate: Int? { nil }

    /// Last generation/transcoding of the format, in microseconds.
    var lastModified: UInt64 { 0 }

    /// Non-documented string attached to some formats.
    var xtags: String { "" }

    /// Frame width in pixels. `nil` for audio-only adaptive formats.
    var width: Int? { nil }

    /// Frame height in pixels. `nil` for audio-only adaptive formats.
    var height: Int? { nil }

    /// Boolean indicating whether Dynamic Range Compression is
    /// applied. Always
    /// `false`/irrelevant for video-only formats.
    var isDrc: Bool { false }
}
