//
//  NetworkError.swift
//
//
//  Created by Antoine Bollengier on 01.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// A struct representing a network error.
public struct NetworkError: Error {
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}
