//
//  DownloadFormat.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Protocol representing a particular video/audio format that can be downloaded.
public protocol DownloadFormat {
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
    
}
