//
//  ParameterValidator.swift
//
//
//  Created by Antoine Bollengier on 01.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct ParameterValidator: Sendable {
    /// A boolean that indicated whether the existence of the parameter is needed in order for it to succeed.
    public let needExistence: Bool
    
    /// The handler that is executed to check if a parameter's value is valid and modify it if necessary. Returns a optional string if everything is fine (should override the request's actual parameter in case it's not nil) or a ``ValidationError``.
    public let handler: @Sendable (String?) -> Result<String?, ValidationError>
    
    /// - Parameter needExistence: A boolean that indicated whether the existence of the parameter is needed in order for it to succeed.
    /// - Parameter validator: The handler that is executed to check if a parameter's value is valid and modify it if necessary. Returns a optional string if everything is fine (should override the request's actual parameter) or a ``ValidationError``.
    public init(needExistence: Bool = true, validator: @escaping @Sendable (String?) -> Result<String?, ValidationError>) {
        self.needExistence = needExistence
        self.handler = validator
    }
    
    /// Combine this validator with another, if the two affect the final parameter, the validator from when this method is called will be called first.
    public func combine(with otherValidator: ParameterValidator) -> ParameterValidator {
        return ParameterValidator(needExistence: self.needExistence /* we don't do an OR operation with the other validator as the current one could introduce a default value for nil values */, validator: { parameter in
            switch self.handler(parameter) {
            case .success(let result):
                guard otherValidator.needExistence && result == nil else { return .failure(ValidationError(reason: "Nil value.", validatorFailedNameDescriptor: "Combination of \(String(describing: self)) and \(String(describing: otherValidator))")) }
                return otherValidator.handler(parameter)
            case .failure(let error):
                return .failure(error)
            }
        })
    }

    /// A struct representing an error returned by a validator's handler.
    public struct ValidationError: Error {
        
        /// A string describing the reason of the error.
        public let reason: String
        
        /// A string describing the validator's role.
        public let validatorFailedNameDescriptor: String
        
        /// - Parameter reason: A string describing the reason of the error.
        /// - Parameter validatorFailedNameDescriptor: A string describing the validator's role.
        public init(reason: String, validatorFailedNameDescriptor: String) {
            self.reason = reason
            self.validatorFailedNameDescriptor = validatorFailedNameDescriptor
        }
    }
    
    /// A struct representing an error returned by a validator's handler.
    public struct TypedValidationError: Error {
        /// The type of data concerned by the error.
        public let dataType: HeadersList.AddQueryInfo.ContentTypes
        
        /// A string describing the reason of the error.
        public let reason: String
        
        /// A string describing the validator's role.
        public let validatorFailedNameDescriptor: String
        
        /// - Parameter dataType: The type of data concerned by the error.
        /// - Parameter reason: A string describing the reason of the error.
        /// - Parameter validatorFailedNameDescriptor: A string describing the validator's role.
        public init(dataType: HeadersList.AddQueryInfo.ContentTypes, reason: String, validatorFailedNameDescriptor: String) {
            self.dataType = dataType
            self.reason = reason
            self.validatorFailedNameDescriptor = validatorFailedNameDescriptor
        }
    }
}
