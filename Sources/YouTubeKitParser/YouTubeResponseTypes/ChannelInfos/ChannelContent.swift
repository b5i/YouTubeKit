//
//  ChannelContent.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Protocol to make conform to a decodable channel content like channel's video, shorts, directs or even playlists.
public protocol ChannelContent: Sendable {
    /// Type of the content, associated with a ``ChannelInfosResponse/RequestTypes`` type.
    static var type: ChannelInfosResponse.RequestTypes { get }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use decodeJSONFromTab(_ json: JSON, channelInfos: YTLittleChannelInfos?) instead. You can convert your Data into JSON by calling the JSON(_ data: Data) initializer.") // deprecated as you can't really find some tab JSON in raw data.
    /// Decode from a "tab" YouTube JSON dictionnary a ChannelContent
    /// - Parameter data: JSON encoded in Data representing a "tabRenderer".
    /// - Parameter channelInfos: A piece of information about the channel that will be used to complete the informations in the results that are often missing.
    /// - Returns: a ChannelContent
    static func decodeJSONFromTab(_ data: Data, channelInfos: YTLittleChannelInfos?) -> Self?
    
    /// Decode from a "tab" YouTube JSON dictionnary a ChannelContent
    /// - Parameter data: some JSON representing a "tabRenderer".
    /// - Parameter channelInfos: A piece of information about the channel that will be used to complete the informations in the results that are often missing.
    /// - Returns: a ChannelContent
    static func decodeJSONFromTab(_ json: JSON, channelInfos: YTLittleChannelInfos?) -> Self?
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use canDecode(json: JSON) instead. You can convert your Data into JSON by calling the JSON(_ data: Data) initializer.") // deprecated as you can't really find some tab JSON in raw data.
    /// Boolean indicating if some Data can be decoded to give an instance of this ``ChannelContent`` type.
    /// - Parameter data: the Data to be checked.
    /// - Returns: the boolean that indicate if a decoding would be possible.
    static func canDecode(data: Data) -> Bool
    
    /// Method that returns a boolean indicating if some JSON can be decoded to give an instance of this ``ChannelContent`` type.
    /// - Parameter json: the JSON to be checked, must have a direct dictionnary child named "tabRenderer".
    /// - Returns: the boolean that indicate if a decoding would be possible.
    static func canDecode(json: JSON) -> Bool
    
    /// Takes some JSON and decode it to give a continuation result.
    /// - Parameter json: the JSON to be decoded.
    /// - Returns: a continuation result.
    static func decodeContinuation(json: JSON) -> ChannelInfosResponse.ContentContinuation<Self>
    
    /// Method that extracts the continuation token in case there is one.
    /// - Parameter json: the JSON that will be used to extract the token.
    /// - Returns: an optional string (nil if there is no continuation token), representing the continuation token.
    static func getContinuationFromTab(json: JSON) -> String?
    
    /// To check whether a part of JSON is a tab of the concerned ``ChannelContent`` type.
    /// - Parameter json: the JSON to be checked.
    /// - Returns: a boolean indicating if the tab is of the concerned ``ChannelContent`` type.
    ///
    /// This method will decode check from a JSON dictionnary of name "tabRenderer".
    static func isTabOfSelfType(json: JSON) -> Bool
}
