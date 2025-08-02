//
//  AccountInfosResponse.swift
//
//
//  Created by Antoine Bollengier on 15.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// Response containing information about the account.
public struct AccountInfosResponse: AuthenticatedResponse {
    public static let headersType: HeaderTypes = .userAccountHeaders
    
    public static let parametersValidationList: ValidationList = [:]
    
    public var isDisconnected: Bool = true
    
    /// The name of the account.
    public var name: String?
    
    /// An array of ``YTThumbnail`` representing the avatar of the user.
    public var avatar: [YTThumbnail] = []
    
    /// The channelHandle of the user, can be nil if the user does not have a channel.
    public var channelHandle: String?
        
    public static func decodeJSON(json: JSON) -> AccountInfosResponse {
        var toReturn = AccountInfosResponse()
        
        guard !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        for action in json["actions"].arrayValue {
            let accountInfos = action["openPopupAction", "popup", "multiPageMenuRenderer", "header", "activeAccountHeaderRenderer"]
            if accountInfos.exists() {
                YTThumbnail.appendThumbnails(json: accountInfos["accountPhoto"], thumbnailList: &toReturn.avatar)
                
                toReturn.channelHandle = accountInfos["channelHandle", "simpleText"].string
                
                toReturn.name = accountInfos["accountName", "simpleText"].string
                
                break
            }
        }
        
        return toReturn
    }
}
