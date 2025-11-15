//
//  SimpleOperationAuthenticatedResponse.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

public protocol SimpleActionAuthenticatedResponse: AuthenticatedResponse {
    /// Boolean indicating whether the action was successful.
    var success: Bool { get }
}
