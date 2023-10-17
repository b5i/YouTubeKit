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
        LikeVideoResponse.sendRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { _, error in
            result(error)
        })
    }
    
    /// Like the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func likeVideo(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            likeVideo(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: (error))
            })
        })
    }
    
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func dislikeVideo(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        DislikeVideoResponse.sendRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { _, error in
            result(error)
        })
    }
    
    /// Dislike the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func dislikeVideo(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            dislikeVideo(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: (error))
            })
        })
    }
    
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func removeLikeFromVideo(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        RemoveLikeFromVideoResponse.sendRequest(youtubeModel: youtubeModel, data: [.query: self.videoId], result: { _, error in
            result(error)
        })
    }
    
    /// Remove the like/dislike from the video.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func removeLikeFromVideo(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            removeLikeFromVideo(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: (error))
            })
        })
    }
}
