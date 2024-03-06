//
//  YouTubeResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Define a particular YouTube response and how to process it.
///
/// e.g.
/// ```swift
/// struct MyCustomResponse: YouTubeResponse {
///     static var headersType: HeaderTypes = .exampleHeadersType
///
///     static var parametersValidationList: ValidationList = [:]
///
///     static func decodeData(data: Data) -> MyCustomResponse {
///         ///Extract the data from the JSON here and return a MyCustomResponse
///         var myNewCustomResponse = MyCustomResponse()
///         var myJSON = JSON(data)
///         myNewCustomResponse.name = myJSON["name"].string
///         myNewCustomResponse.id = myJSON["id"].int
///     }
///
///     var name: String?
///     var id: Int?
/// }
/// ```
public protocol YouTubeResponse {
    typealias DataRequestType = HeadersList.AddQueryInfo.ContentTypes
    typealias ValidationList = [DataRequestType: ParameterValidator]
    typealias RequestData = [DataRequestType: String]
    
    /// Headers type defined to make the request with the required headers.
    static var headersType: HeaderTypes { get }
    
    /// A list of validators that will check if the provided request's data is correct, to use multiple validators for a ``DataRequestType``, use the combine method of one the validators.
    static var parametersValidationList: ValidationList { get }
    
    /// A function that validates the data from a request. Throws a ``BadRequestDataError`` if it encounters one or multiple errors.
    static func validateRequest(data: inout RequestData) throws
    
    /// A function to decode the data and create an instance of the struct.
    static func decodeData(data: Data) -> Self
    
    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool?,
        result: @escaping (Result<Self, Error>) -> ()
    )

    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeResponse/sendRequest(youtubeModel:data:useCookies:result:)``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool?
    ) async throws -> Self
}

public extension YouTubeResponse {
    
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool? = nil,
        result: @escaping (Result<Self, Error>) -> ()
    ) {
        /// Call YouTubeModel's `sendRequest` function to have a more readable use.
        youtubeModel.sendRequest(
            responseType: Self.self,
            data: data,
            useCookies: useCookies,
            result: result
        )
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool? = nil
    ) async throws -> Self {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Self, Error>) in
            sendRequest(youtubeModel: youtubeModel, data: data, useCookies: useCookies, result: { result in
                continuation.resume(with: result)
            })
        })
    }
}

public extension YouTubeResponse {
    static func validateRequest(data: inout RequestData) throws {
        var errors: [ParameterValidator.TypedValidationError] = []
        
        for (contentType, validator) in self.parametersValidationList {
            if validator.needExistence && data[contentType] == nil {
                errors.append(
                    .init(dataType: contentType, reason: "DataType \(contentType.rawValue) parameter was not provided but is required.", validatorFailedNameDescriptor: "NeedExistence default validator.")
                )
                continue
            }
            
            switch validator.handler(data[contentType]) {
            case .success(let newParameter):
                data[contentType] = newParameter
            case .failure(let error):
                errors.append(.init(dataType: contentType, reason: error.reason, validatorFailedNameDescriptor: error.validatorFailedNameDescriptor))
            }
        }
        
        if !errors.isEmpty {
            throw BadRequestDataError(parametersValidatorErrors: errors)
        }
    }
}
