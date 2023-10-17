//
//  AccountInfosResponse.swift
//
//
//  Created by Antoine Bollengier on 15.10.2023.
//

import Foundation

public struct AccountInfosResponse: AuthenticatedResponse {
    public static var headersType: HeaderTypes = .userAccountHeaders
    
    public var isDisconnected: Bool = true
    
    /// The name of the account.
    public var name: String?
    
    /// An array of ``YTThumbnail`` representing the avatar of the user.
    public var avatar: [YTThumbnail] = []
    
    /// The channelHandle of the user, can be nil if the user does not have a channel.
    public var channelHandle: String?
        
    public static func decodeData(data: Data) -> AccountInfosResponse {
        let json = JSON(data)
        var toReturn = AccountInfosResponse()
        
        guard !(json["responseContext"]["mainAppWebResponseContext"]["loggedOut"].bool ?? true) else { return toReturn }
        
        toReturn.isDisconnected = false
        
        for action in json["actions"].arrayValue {
            let accountInfos = action["openPopupAction"]["popup"]["multiPageMenuRenderer"]["header"]["activeAccountHeaderRenderer"]
            if accountInfos.exists() {
                YTThumbnail.appendThumbnails(json: accountInfos["accountPhoto"], thumbnailList: &toReturn.avatar)
                
                toReturn.channelHandle = accountInfos["channelHandle"]["simpleText"].string
                
                toReturn.name = accountInfos["accountName"]["simpleText"].string
                
                break
            }
        }
        
        return toReturn
    }
}
