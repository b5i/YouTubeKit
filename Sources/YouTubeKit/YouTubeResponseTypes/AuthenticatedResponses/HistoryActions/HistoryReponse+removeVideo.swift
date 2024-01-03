//
//  HistoryReponse+removeVideo.swift
//
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import Foundation

public extension HistoryResponse {
    /// Remove the video from the account's history.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeVideo(withSuppressToken suppressToken: String, youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        RemoveVideoFromHistroryResponse.sendRequest(youtubeModel: youtubeModel, data: [.movingVideoId: suppressToken], result: { (response: RemoveVideoFromHistroryResponse?, error: Error?) in
            if let response = response {
                if response.isDisconnected {
                    result("Could not connect account.")
                } else if response.success {
                    result(nil)
                } else {
                    result("Removing video was not successful.")
                }
            } else {
                result(error ?? "No error while trying to remove a video, weird...")
            }
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
