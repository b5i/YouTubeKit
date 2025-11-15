//
//  UnsubscribeChannelResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct UnsubscribeChannelResponse: SimpleActionAuthenticatedResponse {
    public static let headersType: HeaderTypes = .unsubscribeFromChannelHeaders
    
    public static let parametersValidationList: ValidationList = [.browseId: .channelIdValidator]
    
    public var isDisconnected: Bool = true
    
    /// Boolean indicating whether the append action was successful.
    public var success: Bool = false
    
    public var channelId: String?
    
    public static func decodeJSON(json: JSON) -> UnsubscribeChannelResponse {
        var toReturn = UnsubscribeChannelResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
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
