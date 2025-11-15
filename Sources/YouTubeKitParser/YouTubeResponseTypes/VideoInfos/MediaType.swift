//
//  MediaType.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Different types of medias.
public enum MediaType: Sendable {
    /// Video media, usually includes the audio inside.
    case video
    
    /// Only audio media.
    case audio
}
