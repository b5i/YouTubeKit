//
//  YouTubeVideo+likeActions.swift
//  
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension YouTubeVideo {
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func likeVideo(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        LikeVideoResponse.sendRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { response in
            switch response {
            case .success(let data):
                if data.isDisconnected {
                    result("Failed to like video because the account is disconnected.")
                } else {
                    result(nil)
                }
            case .failure(let error):
                result(error)
            }
        })
    }
    
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func likeVideo(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            likeVideo(youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
    
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func dislikeVideo(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        DislikeVideoResponse.sendRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { response in
            switch response {
            case .success(let data):
                if data.isDisconnected {
                    result("Failed to dislike video because the account is disconnected.")
                } else {
                    result(nil)
                }
            case .failure(let error):
                result(error)
            }
        })
    }
    
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func dislikeVideo(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            dislikeVideo(youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
    
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeLikeFromVideo(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        RemoveLikeFromVideoResponse.sendRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { response in
            switch response {
            case .success(let data):
                if data.isDisconnected {
                    result("Failed to remove like from video because the account is disconnected.")
                } else {
                    result(nil)
                }
            case .failure(let error):
                result(error)
            }
        })
    }
    
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func removeLikeFromVideo(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            removeLikeFromVideo(youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
}
