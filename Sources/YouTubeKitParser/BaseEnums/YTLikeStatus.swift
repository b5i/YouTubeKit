//
//  YTLikeStatus.swift
//  
//
//  Created by Antoine Bollengier on 02.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

/// Enum representing the different "appreciation" status of an account for an item (e.g. a video or a comment).
public enum YTLikeStatus: Sendable, Codable {
    case liked
    case disliked
    case nothing
}
