//
//  AuthenticatedResponse.swift
//
//
//  Created by Antoine Bollengier on 15.10.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

public protocol AuthenticatedResponse: YouTubeResponse {
    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        result: @escaping (Result<Self, Error>) -> ()
    )

    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeResponse/sendRequest(youtubeModel:data:useCookies:result:)``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String]
    ) async throws -> Self
    
    /// Boolean indicating whether the response has a valid result or not (if it was disconnected then it couldn't end up with a valid response).
    var isDisconnected: Bool { get }
}

public extension AuthenticatedResponse {
    
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        result: @escaping (Result<Self, Error>) -> ()
    ) {
        if youtubeModel.cookies != "" && youtubeModel.cookies != "" {
            /// Call YouTubeModel's `sendRequest` function to have a more readable use.
            youtubeModel.sendRequest(
                responseType: Self.self,
                data: data,
                useCookies: true,
                result: result
            )
        } else {
            result(.failure("Authentification cookies not provided: youtubeModel.cookies = \(String(describing: youtubeModel.cookies))"))
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String]
    ) async throws -> Self {
        guard youtubeModel.cookies != "" && youtubeModel.cookies != "" else { throw "Authentification cookies not provided: youtubeModel.cookies = \(String(describing: youtubeModel.cookies))" }
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Self, Error>) in
            sendRequest(youtubeModel: youtubeModel, data: data, useCookies: true, result: { result in
                continuation.resume(with: result)
            })
        })
    }
}
