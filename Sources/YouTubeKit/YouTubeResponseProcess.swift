//
//  YouTubeResponseProcess.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public protocol YouTubeResponse {
    static var headersType: HeaderTypes { get }
    static func decodeData(data: Data) -> Self
}

public func processJSONResponse<ResponseType: YouTubeResponse>(data: Data, type: ResponseType) -> ResponseType {
    return ResponseType.decodeData(data: data)
}
