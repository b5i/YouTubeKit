//
//  AccountConnectionError.swift
//
//
//  Created by Antoine Bollengier on 01.03.2024.
//

import Foundation

/// A struct representing an error in relation with the account used in the request.
public struct AccountConnectionError: Error {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
