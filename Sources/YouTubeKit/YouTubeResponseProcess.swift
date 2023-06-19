//
//  YouTubeResponseProcess.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Define a particular YouTube response and how to process it.
///
/// e.g.
/// ```
/// struct MyCustomResponse: YouTubeResponse {
///     static var headersType: HeaderTypes = .exampleHeadersType
///     static func decodeData(data: Data) -> MyCustomResponse {
///         ///Extract the data from the JSON here and return a MyCustomResponse
///         var myNewCustomResponse = MyCustomResponse()
///         var myJSON = JSON(data)
///         myNewCustomResponse.name = myJSON["name"].string
///         myNewCustomResponse.id = myJSON["id"].int
///     }
///
///     var name: String?
///     var id: Int?
/// }
/// ```
public protocol YouTubeResponse {
    /// Headers type defined to make the request with the required headers.
    static var headersType: HeaderTypes { get }
    
    /// A function to decode the data and create an instance of the struct.
    static func decodeData(data: Data) -> Self
}
