//
//  YouTubeVideo+getCaptions.swift
//  
//
//  Created by Antoine Bollengier on 27.06.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

public extension YouTubeVideo {
    /// Get the captions for the current video.
    static func getCaptions(youtubeModel: YouTubeModel, captionType: YTCaption, result: @escaping @Sendable (Result<VideoCaptionsResponse, Error>) -> Void) {
        VideoCaptionsResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.customURL: captionType.url.absoluteString], result: { response in
            switch response {
            case .success(let data):
                result(.success(data))
            case .failure(let error):
                result(.failure(error))
            }
        })
    }
    
    /// Get the captions for the current video.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func getCaptionsThrowing(youtubeModel: YouTubeModel, captionType: YTCaption) async throws -> VideoCaptionsResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<VideoCaptionsResponse, Error>) in
            self.getCaptions(youtubeModel: youtubeModel, captionType: captionType, result: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    /// Get the captions for the current video.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func getCaptions(youtubeModel: YouTubeModel, captionType: YTCaption) async -> Result<VideoCaptionsResponse, Error> {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Result<VideoCaptionsResponse, Error>, Never>) in
            self.getCaptions(youtubeModel: youtubeModel, captionType: captionType, result: { result in
                continuation.resume(returning: result)
            })
        })
    }
}
