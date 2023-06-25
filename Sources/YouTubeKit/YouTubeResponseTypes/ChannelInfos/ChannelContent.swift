//
//  ChannelContent.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 23.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Protocol to make conform to a decodable channel content like channel's video, shorts, directs or even playlists.
public protocol ChannelContent {
    /// Type of the content, associated with a ``ChannelInfosResponse/RequestTypes`` type.
    static var type: ChannelInfosResponse.RequestTypes { get }
    
    /// Decode from a "tab" YouTube JSON dictionnary a ChannelContent
    /// - Parameter data: JSON encoded in Data representing a "tabRenderer".
    /// - Returns: a ChannelContent
    static func decodeJSONFromTab(_ data: Data, channelInfos: YTLittleChannelInfos?) -> Self?
    
    /// Decode from a "tab" YouTube JSON dictionnary a ChannelContent
    /// - Parameter data: some JSON representing a "tabRenderer".
    /// - Returns: a ChannelContent
    static func decodeJSONFromTab(_ json: JSON, channelInfos: YTLittleChannelInfos?) -> Self?
    
    /// Boolean indicating if some Data can be decoded to give an instance of this ``ChannelContent`` type.
    /// - Parameter data: the Data to be checked.
    /// - Returns: the boolean that indicate if a decoding would be possible.
    static func canDecode(data: Data) -> Bool
    
    /// Method that returns a boolean indicating if some JSON can be decoded to give an instance of this ``ChannelContent`` type.
    /// - Parameter json: the JSON to be checked.
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
    
    /// To check wether a part of JSON is a tab of the concerned ``ChannelContent`` type.
    /// - Parameter json: the JSON to be checked.
    /// - Returns: a boolean indicating if the tab is of the concerned ``ChannelContent`` type.
    ///
    /// This method will decode check from a JSON dictionnary of name "tabRenderer".
    static func isTabOfSelfType(json: JSON) -> Bool
}
