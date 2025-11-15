//
//  HistoryReponse+removeVideo.swift
//
//
//  Created by Antoine Bollengier on 03.01.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension HistoryResponse {
    /// Remove the video from the account's history.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeVideo(withSuppressToken suppressToken: String, youtubeModel: YouTubeModel, result: @escaping @Sendable (Error?) -> Void) {
        RemoveVideoFromHistroryResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.movingVideoId: suppressToken], result: { response in
            switch response {
            case .success(let response):
                if response.isDisconnected {
                    result("Failed to remove video from history because no account is connected.")
                } else if response.success {
                    result(nil)
                } else {
                    result("Removing video was not successful.")
                }
            case .failure(let error):
                result(error)
            }
        })
    }
    
    /// Remove the video from the account's history.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func removeVideoThrowing(withSuppressToken suppressToken: String, youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            removeVideo(withSuppressToken: suppressToken, youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
    
    
    /// Remove the video from the account's history.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func removeVideo(withSuppressToken suppressToken: String, youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            removeVideo(withSuppressToken: suppressToken, youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: error)
            })
        })
    }
}
