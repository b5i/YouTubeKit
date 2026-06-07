//
//  EndScreen.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 11.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

public struct EndScreen: Sendable {
    /// The start time in milliseconds of the end screen.
    public var startTime: Int?
    
    public var elements: [EndScreenElement] = []
}
