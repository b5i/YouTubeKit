//
//  String+ytkRegexMatches.swift
//
//
//  Created by Antoine Bollengier on 09.05.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

public extension String {
    // adapted from https://stackoverflow.com/a/27880748/16456439
    /// A method to return all the matches for a certain regular expression.
    /// Every sub-array starts with the whole match and the capture groups follow.
    func ytkRegexMatches(for regex: NSRegularExpression) -> [[String]] {
        return regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            .map { match in
                var returnArray: [String] = []
                for rangeIndex in 0..<match.numberOfRanges {
                    if let range = Range(match.range(at: rangeIndex), in: self) {
                        returnArray.append(String(self[range]))
                    }
                }
                return returnArray
            }
    }
    
    /// A method to return all the matches for a certain regular expression.
    /// Every sub-array starts with the whole match and the capture groups follow.
    func ytkRegexMatches(for stringRegex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: stringRegex) else { return [] }
        return self.ytkRegexMatches(for: regex)
    }
    
    /// Gets the first capture group of the first match.
    func ytkFirstGroupMatch(for regex: NSRegularExpression) -> String? {
        return self.ytkRegexMatches(for: regex).first?.dropFirst().first
    }
    
    /// Gets the first capture group of the first match.
    func ytkFirstGroupMatch(for stringRegex: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: stringRegex) else { return nil }
        return self.ytkFirstGroupMatch(for: regex)
    }
}
