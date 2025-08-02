//
//  ParameterValidator+commonValidators.swift
//
//
//  Created by Antoine Bollengier on 01.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension ParameterValidator {
    static let videoIdValidator = ParameterValidator(validator: { videoId in
        let validatorName = "VideoId validator"
        guard let videoId = videoId else { return .failure(.init(reason: "Nil value.", validatorFailedNameDescriptor: validatorName))}
        
        // https://webapps.stackexchange.com/a/101153
        guard videoId.count == 11, let lastChar = videoId.last else { return .failure(.init(reason: "The videoId does not contain exactly 11 characters." /* this can change in the future */, validatorFailedNameDescriptor: validatorName))}
        
        guard "048AEIMQUYcgkosw".contains(lastChar) else { return .failure(.init(reason: "Last character of videoId is not valid, should be included in 048AEIMQUYcgkosw, current videoId: \(videoId)", validatorFailedNameDescriptor: validatorName))}
        
        return .success(videoId)
    })
    
    static let existenceValidator = ParameterValidator(validator: { parameter in
        if parameter == nil {
            return .failure(.init(reason: "Parameter is nil.", validatorFailedNameDescriptor: "ExistenceValidator."))
        } else {
            return .success(parameter)
        }
    })
    
    static let textSanitizerValidator = ParameterValidator(validator: { parameter in
        if let parameter = parameter {
            return .success(parameter.replacingOccurrences(of: "\\", with: #"\\"#).replacingOccurrences(of: "\"", with: #"\""#))
        } else {
            return .failure(.init(reason: "Parameter is nil.", validatorFailedNameDescriptor: "ExistenceValidator."))
        }
    })
    
    static let channelIdValidator = ParameterValidator(validator: { channelId in
        let validatorName = "ChannelId validator"
        guard let channelId = channelId else { return .failure(.init(reason: "Nil value.", validatorFailedNameDescriptor: validatorName))}
        
        // https://webapps.stackexchange.com/a/101153
        
        let idCount = channelId.count
        
        guard idCount == 22 || idCount == 24, let lastChar = channelId.last else { return .failure(.init(reason: "The channelId does not contain exactly 22 or 24 characters." /* this can change in the future */, validatorFailedNameDescriptor: validatorName))}
        
        guard "AQgw".contains(lastChar) else { return .failure(.init(reason: "Last character of channelId is not valid, should be included in AQgw, current channelId: \(channelId)", validatorFailedNameDescriptor: validatorName))}
        
        return .success(channelId)
    })
    
    static let playlistIdWithVLPrefixValidator = ParameterValidator(validator: { playlistId in
        let validatorName = "PlaylistId with VL prefix validator"
        guard let playlistId = playlistId, !playlistId.isEmpty else { return .failure(.init(reason: "Nil or empty value.", validatorFailedNameDescriptor: validatorName))}
        
        if playlistId.hasPrefix("VL") {
            return .success(playlistId)
        } else {
            return .success("VL" + playlistId)
        }
    })
    
    static let playlistIdWithoutVLPrefixValidator = ParameterValidator(validator: { playlistId in
        let validatorName = "PlaylistId without VL prefix validator"
        guard let playlistId = playlistId, !playlistId.isEmpty else { return .failure(.init(reason: "Nil or empty value.", validatorFailedNameDescriptor: validatorName))}
        
        if playlistId.hasPrefix("VL") {
            return .success(String(playlistId.dropFirst(2)))
        } else {
            return .success(playlistId)
        }
    })
    
    static let privacyValidator = ParameterValidator(validator: { privacy in
        let validatorName = "Privacy validator"
        guard let privacy = privacy else { return .failure(.init(reason: "Nil value.", validatorFailedNameDescriptor: validatorName))}
        
        if YTPrivacy(rawValue: privacy) == nil {
            return .failure(.init(reason: "Given privacy is not valid, received: \(privacy) but expected one of those: \(YTPrivacy.allCases.map({$0.rawValue})). Make sure you pass the rawValue of one of the YTPrivacy.", validatorFailedNameDescriptor: validatorName))
        } else {
            return .success(privacy)
        }
    })
    
    static let urlValidator = ParameterValidator(validator: { url in
        let validatorName = "URL validator"
        
        guard let url = url else { return .failure(.init(reason: "Nil value.", validatorFailedNameDescriptor: validatorName)) } // should never be called because of the needExistence
        
        if URL(string: url) != nil {            
            return .success(url)
        } else {
            return .failure(.init(reason: "Given url is not a valid URL.", validatorFailedNameDescriptor: validatorName))
        }
    })
}
