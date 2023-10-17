//
//  UnsubscribeChannelResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//

import Foundation

public struct UnsubscribeChannelResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .unsubscribeFromChannelHeaders
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the append action was successful.
    public var success: Bool = false
    
    public var channelId: String?
    
    public static func decodeData(data: Data) -> UnsubscribeChannelResponse {
        let json = JSON(data)
        var toReturn = UnsubscribeChannelResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        for action in json["actions"].arrayValue {
            let subscribeButton = action["updateSubscribeButtonAction"]
            if subscribeButton.exists() {
                toReturn.channelId = subscribeButton["channelId"].string
                toReturn.success = !subscribeButton["subscribed"].boolValue
            }
        }
        
        return toReturn
    }
}
