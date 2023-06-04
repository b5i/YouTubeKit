//
//  YouTubeRequests.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

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
    let headers = YouTubeHeaders.shared.getHeaders(forType: ResponseType.headersType)
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
    
    let task = URLSession.shared.dataTask(with: request) { data, _, error in
        if let data = data {
            result(ResponseType.decodeData(data: data), error)
        }
        result(nil, error)
    }
    task.resume()
}
