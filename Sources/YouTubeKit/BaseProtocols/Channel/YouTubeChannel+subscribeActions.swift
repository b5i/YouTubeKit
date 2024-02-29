//
//  YouTubeChannel+subscribeActions.swift
//
//
//  Created by Antoine Bollengier on 17.10.2023.
//

import Foundation

public extension YouTubeChannel {
    /// Subscribe to the channel.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func subscribe(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        SubscribeChannelResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.channelId], result: { response in
            switch response {
            case .success(let data):
                if data.success {
                    result(nil)
                } else {
                    result("Failed to subscribe to channel: with id \(String(describing: data.channelId)).")
                }
            case .failure(let error):
                result(error)
            }
        })
    }
    
    /// Subscribe to the channel.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func subscribe(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            subscribe(youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
    
    /// Unsubscribe to the channel.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func unsubscribe(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        UnsubscribeChannelResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.channelId], result: { response in
            switch response {
            case .success(let data):
                if data.success {
                    result(nil)
                } else {
                    result("Failed to subscribe to channel with id: \(String(describing: data.channelId))")
                }
            case .failure(let error):
                result(error)
            }
        })
    }
    
    /// Unsubscribe to the channel.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func unsubscribe(youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            unsubscribe(youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
}
