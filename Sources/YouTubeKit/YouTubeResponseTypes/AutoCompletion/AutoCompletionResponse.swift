//
//  AutoCompletionResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing an search AutoCompletion response.
///
/// Note: by using this request you consent to YouTube's cookie policy (even if no cookies are kept wiht YouTubeKit).
public struct AutoCompletionResponse: YouTubeResponse {
    public static let headersType: HeaderTypes = .autoCompletion
    
    public static let parametersValidationList: ValidationList = [.query: .existenceValidator]
    
    /// Text query used to get the search suggestions.
    public var initialQuery: String = ""
    
    /// An array of string representing the search suggestion, usually sorted by relevance from most to least.
    public var autoCompletionEntries: [String] = []
    
    public static func decodeData(data: Data) throws -> AutoCompletionResponse {
        guard var dataString = String(data: data, encoding: String.Encoding.windowsCP1254)?
            .replacingOccurrences(of: "window.google.ac.h(", with: "") else { throw ResponseExtractionError(reponseType: Self.self, stepDescription: "Couldn't convert the response data to a string.") }
        dataString = String(dataString.dropLast())
        
        let json = JSON(parseJSON: dataString)
        
        try self.checkForErrors(json: json)
        
        return decodeJSON(json: json)
    }
    
    public static func decodeJSON(json: JSON) -> AutoCompletionResponse {
        var response = AutoCompletionResponse()

        
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
            } else if let autoCompletionEntriesArray = jsonElement.array {
                for autoCompletionEntry in autoCompletionEntriesArray {
                    if let autoCompletionEntry = autoCompletionEntry.array {
                        for entryPartsOfArray in autoCompletionEntry {
                            guard let entryString = entryPartsOfArray.string else { continue }
                            response.autoCompletionEntries.append(entryString)
                            break
                        }
                    }
                }
            }
            /// We don't care of the dictionnary with unknown strings and integers
        }
        
        return response
    }
}
