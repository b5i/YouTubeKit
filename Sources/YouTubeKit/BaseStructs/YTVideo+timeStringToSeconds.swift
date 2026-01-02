//
//  YTVideo+timeStringToSeconds.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 02.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

public extension YTVideo {
    /// Converts a time string (e.g. "1:30") to seconds.
    /// - Parameter timeString: The time string to convert.
    /// - Returns: The time in seconds, or nil if the format is invalid.
    static func timeStringToSeconds(_ timeString: String) -> Int? {
        let components = timeString.split(separator: ":").map(String.init)
        guard components.count <= 2 else { return nil }
        
        let seconds = components.reversed().enumerated().reduce(0) { (total, element) in
            guard let value = Int(element.element) else { return total }
            return total + value * Int(pow(60, Double(element.offset)))
        }
        return seconds
    }
}
