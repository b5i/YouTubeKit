//
//  ResponseExtractionError.swift
//  
//
//  Created by Antoine Bollengier on 17.06.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

/// A struct representing a network error.
public struct ResponseExtractionError: Error {
    public let reponseType: any YouTubeResponse.Type
    public let stepDescription: String
    
    public init(reponseType: any YouTubeResponse.Type, stepDescription: String) {
        self.reponseType = reponseType
        self.stepDescription = stepDescription
    }
    
    public var localizedDescription: String {
        return "Failed to extract response of type \(reponseType) at critical step: \(stepDescription)."
    }
}
