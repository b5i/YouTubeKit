//
//  YTSearchResult.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 19.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Protocol representing a search result.
public protocol YTSearchResult: Codable, Equatable {
    /// Defines the item's type, for example a video or a channel.
    ///
    /// You can filter array of YTSearchResult conform items using
    ///
    ///     var array: [any YTSearchResult] = ...
    ///     array.filterTypes(acceptedTypes: [.video])
    ///
    /// to get videos only for example.
    static var type: YTSearchResultType { get }
    
    /// Decode and process the JSON from Data, and give a decoded version of it..
    /// - Parameter data: the JSON encoded in Data.
    /// - Returns: an instance of the decoded JSON object.
    static func decodeJSON(data: Data) -> Self
    
    /// Process the JSON and give a decoded version of it.
    /// - Parameter json: the JSON that has to be decoded.
    /// - Returns: an instance of the decoded JSON object.
    static func decodeJSON(json: JSON) -> Self
    
    /// Identifier of the item in the request result array, useful when you want to display all your results in the right order.
    /// Has to be defined during the array push operation.
    var id: Int? { get set }
}
