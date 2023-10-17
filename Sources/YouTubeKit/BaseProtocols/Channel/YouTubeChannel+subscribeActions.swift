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
        SubscribeChannelResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.channelId], result: { response, error in
            if let response = response {
                if response.success {
                    result(nil)
                } else {
                    result("Failed to subscribe to channel with id: \(String(describing: response.channelId))")
                }
            } else {
                result(error)
            }
        })
    }
    
    /// Subscribe to the channel.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func subscribe(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            subscribe(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: (error))
            })
        })
    }
    
    /// Unsubscribe to the channel.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    func unsubscribe(youtubeModel: YouTubeModel, result: @escaping (Error?) -> Void) {
        UnsubscribeChannelResponse.sendRequest(youtubeModel: youtubeModel, data: [.browseId: self.channelId], result: { response, error in
            if let response = response {
                if response.success {
                    result(nil)
                } else {
                    result("Failed to subscribe to channel with id: \(String(describing: response.channelId))")
                }
            } else {
                result(error)
            }
        })
    }
    
    /// Unsubscribe to the channel.
    ///
    /// Requires a ``YouTubeModel`` where ``YouTubeModel/cookies`` is defined.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func unsubscribe(youtubeModel: YouTubeModel) async -> Error? {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Error?, Never>) in
            unsubscribe(youtubeModel: youtubeModel, result: { error in
                continuation.resume(returning: (error))
            })
        })
    }
}
