//
//  YouTubeVideo+likeActions.swift
//  
//
//  Created by Antoine Bollengier on 17.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension YouTubeVideo {
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func likeVideo(youtubeModel: YouTubeModel, result: @escaping @Sendable (Error?) -> Void) {
        LikeVideoResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { response in
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
    func likeVideoThrowing(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            self.likeVideo(youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
    
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func likeVideo(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            likeVideo(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: error)
            })
        })
    }
    
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func dislikeVideo(youtubeModel: YouTubeModel, result: @escaping @Sendable (Error?) -> Void) {
        DislikeVideoResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { response in
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
    func dislikeVideoThrowing(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            self.dislikeVideo(youtubeModel: youtubeModel, result: { error in
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
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func dislikeVideo(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            dislikeVideo(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: error)
            })
        })
    }
    
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeLikeFromVideo(youtubeModel: YouTubeModel, result: @escaping @Sendable (Error?) -> Void) {
        RemoveLikeFromVideoResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { response in
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
    func removeLikeFromVideoThrowing(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            self.removeLikeFromVideo(youtubeModel: youtubeModel, result: { error in
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
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func removeLikeFromVideo(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            self.removeLikeFromVideo(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: error)
            })
        })
    }
}
