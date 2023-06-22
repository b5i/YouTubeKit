//
//  AutoCompletionResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public struct AutoCompletionResponse: YouTubeResponse {
    public static var headersType: HeaderTypes = .autoCompletion
    
    public var initialQuery: String = ""
    
    public var autoCompletionEntries: [String] = []
    
    public static func decodeData(data: Data) -> AutoCompletionResponse {
        var response = AutoCompletionResponse()
        var dataString = String(data: data, encoding: .utf8)!.replacingOccurrences(of: "window.google.ac.h(", with: "")
        dataString = String(dataString.dropLast())
        guard let dataFromDataString = dataString.data(using: .utf8) else { return response }
        let json = JSON(dataFromDataString)
        
        /// Responses are like this
        ///
        /// [
        ///     "yourInitialQuery",
        ///     [
        ///         [
        ///             "autoCompletionEntry",
        ///             0,
        ///             [
        ///                 512,
        ///                 433
        ///             ]
        ///         ]
        ///         // and more entries like this
        ///     ],
        ///     {
        ///         "a": "xxxxxxxxxx", // an unknown string
        ///         "j": "x", // an unknown string (usually the string is actually an int)
        ///         "k": x, // an integer
        ///         "q": "xxxxxxx" // an unknown string
        ///     }
        /// ]
        
        guard let jsonArray = json.array else { return response }
        
        for jsonElement in jsonArray {
            if let initialQuery = jsonElement.string {
                response.initialQuery = initialQuery
            } else if let autoCompletionEntryArray = jsonElement.array {
                for autoCompletionEntry in autoCompletionEntryArray {
                    if let autoCompletionString = autoCompletionEntry.string {
                        response.autoCompletionEntries.append(autoCompletionString)
                    }
                }
            }
            /// We don't care of the dictionnary with unknown strings and integers
        }
        
        return response
    }
}
