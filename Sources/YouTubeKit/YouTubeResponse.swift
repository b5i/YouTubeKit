//
//  YouTubeResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Define a particular YouTube response and how to process it.
///
/// e.g.
/// ```swift
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
    
    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool?,
        result: @escaping (Self?, Error?) -> ()
    )

    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeResponse/sendRequest(youtubeModel:data:useCookies:result:)-7p1m2``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool?
    ) async -> (Self?, Error?)

}

public extension YouTubeResponse {
    
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool? = nil,
        result: @escaping (Self?, Error?) -> ()
    ) {
        /// Call YouTubeModel's `sendRequest` function to have a more readable use.
        youtubeModel.sendRequest(
            responseType: Self.self,
            data: data,
            useCookies: useCookies,
            result: result
        )
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool? = nil
    ) async -> (Self?, Error?) {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(Self?, Error?), Never>) in
            sendRequest(youtubeModel: youtubeModel, data: data, useCookies: useCookies, result: { result, error in
                continuation.resume(returning: (result, error))
            })
        })
    }
}
