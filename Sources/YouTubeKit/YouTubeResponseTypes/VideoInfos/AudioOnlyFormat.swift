//
//  AudioOnlyFormat.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 02.08.2025.
//  Copyright © 2025 - 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

public struct AudioOnlyFormat: AdaptiveDownloadFormat {
    public init(averageBitrate: Int? = nil, contentLength: Int? = nil, contentDuration: Int? = nil, isCopyrightedMedia: Bool? = nil, url: URL? = nil, signatureCipher: String? = nil, mimeType: String? = nil, codec: String? = nil, audioSampleRate: Int? = nil, loudness: Double? = nil, formatLocaleInfos: FormatLocaleInfos? = nil, itag: Int = 0, bitrate: Int? = nil, lastModified: UInt64 = 0, xtags: String = "", isDrc: Bool = false) {
        self.averageBitrate = averageBitrate
        self.contentLength = contentLength
        self.contentDuration = contentDuration
        self.isCopyrightedMedia = isCopyrightedMedia
        self.url = url
        self.signatureCipher = signatureCipher
        self.mimeType = mimeType
        self.codec = codec
        self.audioSampleRate = audioSampleRate
        self.loudness = loudness
        self.formatLocaleInfos = formatLocaleInfos
        self.itag = itag
        self.bitrate = bitrate
        self.lastModified = lastModified
        self.xtags = xtags
        self.isDrc = isDrc
    }
    
    /// Protocol properties
    public static let type: MediaType = .audio
    
    public var averageBitrate: Int?
    
    public var contentLength: Int?
    
    public var contentDuration: Int?
    
    public var isCopyrightedMedia: Bool?
    
    public var url: URL?
    
    public var signatureCipher: String?
    
    public var mimeType: String?
    
    public var codec: String?
    
    /// Audio only medias specific infos
    
    /// Sample rate of the audio in hertz.
    public var audioSampleRate: Int?
    
    /// Audio loudness in decibels.
    public var loudness: Double?
    
    /// Infos about the audio track language.
    ///
    /// - Note: it will be present only if the audio is not the original audio of the video.
    public var formatLocaleInfos: FormatLocaleInfos?

    public var itag: Int
    public var bitrate: Int?
    public var lastModified: UInt64
    public var xtags: String
    public var isDrc: Bool
    
    /// - Warning: Not applicable to ``AudioOnlyFormat``.
    public var width: Int? = nil
    
    /// - Warning: Not applicable to ``AudioOnlyFormat``.
    public var height: Int? = nil
    
    /// Struct representing some informations about the audio track language.
    public struct FormatLocaleInfos: Sendable, Hashable {
        public init(displayName: String? = nil, localeId: String? = nil, isDefaultAudioFormat: Bool? = nil, isAutoDubbed: Bool? = nil) {
            self.displayName = displayName
            self.localeId = localeId
            self.isDefaultAudioFormat = isDefaultAudioFormat
            self.isAutoDubbed = isAutoDubbed
        }
        
        /// Name of the language, e.g. "French".
        ///
        /// - Note: the name of the language depends on the ``YouTubeModel``'s locale and the cookie's (if provided) account's default language. E.g. you would get "French" if your cookies point to an english account and "Français" if they pointed to a french one.
        public var displayName: String?
        
        /// Id of the language, generally is the language code that has ".n" has suffix. E.g. "fr.3" or "en.4".
        public var localeId: String?
        
        /// A boolean indicating whether the audio was auto-dubbed by YouTube.
        public var isAutoDubbed: Bool?
        
        /// A boolean indicating whether the format is considered as the default one by YouTube (depends on the ``YouTubeModel``'s locale and the cookie's (if provided) account's default language).
        public var isDefaultAudioFormat: Bool?
    }
}
