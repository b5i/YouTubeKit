//
//  VideoCaptionsResponse.swift
//
//
//  Created by Antoine Bollengier on 27.06.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

/// Struct representing a response containing the captions of a video.
public struct VideoCaptionsResponse: YouTubeResponse {
    public static let headersType: HeaderTypes = .videoCaptionsHeaders
    
    public static let parametersValidationList: ValidationList = [.customURL: .urlValidator]
        
    public var captionParts: [CaptionPart]
    
    public init(captionParts: [CaptionPart]) {
        self.captionParts = captionParts
    }
    
    public static func decodeData(data: Data) throws -> VideoCaptionsResponse {
        var toReturn = VideoCaptionsResponse(captionParts: [])
        
        #if os(macOS)
        let dataText = CFXMLCreateStringByUnescapingEntities(nil, CFXMLCreateStringByUnescapingEntities(nil, String(decoding: data, as: UTF8.self) as CFString, nil), nil) as String
        #else
        let dataText = String(decoding: data, as: UTF8.self)
        #endif
        
        let regexResults = dataText.ytkRegexMatches(for: #"(?:<text start=\"([0-9\.]*)\" dur=\"([0-9\.]*)">([\w\W]*?)<\/text>)"#)
        
        var currentEndTime: Double = Double.infinity
        
        for result in regexResults.reversed() {
            guard result.count == 4 else { continue }
            
            let startTime = Double(result[1]) ?? 0
            let duration = min(Double(result[2]) ?? 0, currentEndTime - startTime)
            
            let text = result[3]
                        
            toReturn.captionParts.append(
                CaptionPart(
                    text: text,
                    startTime: startTime,
                    duration: duration
                )
            )
            
            currentEndTime = startTime
        }
        
        toReturn.captionParts.reverse()

        return toReturn
    }
    
    /// Decode json to give an instance of ``VideoInfosResponse``.
    /// - Parameter json: the json to be decoded.
    /// - Returns: an instance of ``VideoInfosResponse``.
    public static func decodeJSON(json: JSON) throws -> VideoCaptionsResponse {
        throw ResponseExtractionError(reponseType: Self.self, stepDescription: "Can't decode a VideoCaptionsResponse from some raw JSON.")
    }
    
    public func getFormattedString(withFormat format: CaptionFormats) -> String {
        func getTimeString(_ time: Double) -> String {
            let hours: String = String(format: "%02d", Int(time / 3600))
            let minutes: String = String(format: "%02d", Int(time - (time / 3600).rounded(.down) * 3600) / 60)
            let seconds: String = String(format: "%02d", Int(time.truncatingRemainder(dividingBy: 60)))
            let milliseconds: String = String(format: "%03d", Int(time.truncatingRemainder(dividingBy: 1) * 1000))
                        
            return "\(hours):\(minutes):\(seconds)\(format == .vtt ? "." : ",")\(milliseconds)"
        }
        
        return """
                \(format == .vtt ? "WEBVTT\n\n" : "")\(
                self.captionParts.enumerated()
                    .map { offset, captionPart in
                        return """
                               \(offset + 1)
                               \(getTimeString(captionPart.startTime)) --> \(getTimeString(captionPart.startTime + captionPart.duration))
                               \(captionPart.text)
                               """
                    }
                    .joined(separator: "\n\n")
                )
                """
    }
    
    public enum CaptionFormats {
        case vtt
        case srt
    }
    
    public struct CaptionPart: Sendable, Codable {
        /// Text of the caption.
        ///
        /// - Warning: The text might contain HTML entities (if `CFXMLCreateStringByUnescapingEntities` is not present), to remove them, call a function like `CFXMLCreateStringByUnescapingEntities()` two times on the text.
        public var text: String
        
        /// Start time of the caption, in seconds.
        public var startTime: Double
        
        /// Duration of the caption, in seconds.
        public var duration: Double
        
        public init(text: String, startTime: Double, duration: Double) {
            self.text = text
            self.startTime = startTime
            self.duration = duration
        }
    }
}
