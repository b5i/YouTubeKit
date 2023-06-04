//
//  SendRequest.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Send a request of type `ResponseType`to YouTube's API.
/// - Parameters:
///   - responseType: Defines the request/response type, e.g.`SearchResponse.self`
///   - query: See ``HeaderTypes``.
///   - browseId: See ``HeaderTypes``.
///   - params: See ``HeaderTypes``.
///   - continuation: See ``HeaderTypes``.
///   - visitorData: See ``HeaderTypes``.
///   - movingVideoID: See ``HeaderTypes``.
///   - videoBeforeID: See ``HeaderTypes``.
///   - playlistEditToken: See ``HeaderTypes``.
///   - result: Returns the optional ResponseType JSON processing and the optional error that could happen during the network request.
public func sendRequest<ResponseType: YouTubeResponse>(
    responseType: ResponseType.Type,
    query: String = "",
    browseId: String = "",
    params: String = "",
    continuation: String = "",
    visitorData: String = "",
    movingVideoID: String = "",
    videoBeforeID: String = "",
    playlistEditToken: String = "",
    result: @escaping (ResponseType?, Error?) -> ()
) {
    /// Get request headers.
    let headers = YouTubeHeaders.shared.getHeaders(forType: ResponseType.headersType)
    
    /// Create request
    let request = setHeadersAgentFor(
        content: headers,
        query: query,
        browseId: browseId,
        params: params,
        continuation: continuation,
        visitorData: visitorData,
        movingVideoID: movingVideoID,
        videoBeforeID: videoBeforeID,
        playlistEditToken: playlistEditToken
    )
    
    /// Create task with the request
    let task = URLSession.shared.dataTask(with: request) { data, _, error in
        /// Check if the task worked and gave back data.
        if let data = data {
            result(ResponseType.decodeData(data: data), error)
        }
        /// Exectued if the data was nil so there was probably an error.
        result(nil, error)
    }
    
    /// Start it
    task.resume()
}
