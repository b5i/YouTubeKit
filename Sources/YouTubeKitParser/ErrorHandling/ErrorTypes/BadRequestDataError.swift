//
//  BadRequestDataError.swift
//
//
//  Created by Antoine Bollengier on 01.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// A struct representing the error returned when calling ``YouTubeResponse/validateRequest(data:)``
public struct BadRequestDataError: Error {
    /// An array of validation errors.
    public let parametersValidatorErrors: [ParameterValidator.TypedValidationError]
    
    /// - Parameter parametersValidatorErrors: An array of validation errors.
    public init(parametersValidatorErrors: [ParameterValidator.TypedValidationError]) {
        self.parametersValidatorErrors = parametersValidatorErrors
    }
}
