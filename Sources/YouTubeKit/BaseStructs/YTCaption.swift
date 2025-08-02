//
//  YTCaption.swift
//
//
//  Created by Antoine Bollengier on 27.06.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation

public struct YTCaption: Sendable {
    public var languageCode: String
    
    public var languageName: String
    
    public var url: URL
    
    public var isTranslated: Bool
    
    public init(languageCode: String, languageName: String, url: URL, isTranslated: Bool) {
        self.languageCode = languageCode
        self.languageName = languageName
        self.url = url
        self.isTranslated = isTranslated
    }
}
