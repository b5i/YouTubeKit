//
//  YouTubeResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
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
public protocol YouTubeResponse: Sendable {
    typealias DataRequestType = HeadersList.AddQueryInfo.ContentTypes
    typealias ValidationList = [DataRequestType: ParameterValidator]
    typealias RequestData = [DataRequestType: String]
    
    /// Headers type defined to make the request with the required headers.
    static var headersType: HeaderTypes { get }
    
    /// A list of validators that will check if the provided request's data is correct, to use multiple validators for a ``DataRequestType``, use the combine method of one the validators.
    static var parametersValidationList: ValidationList { get }
    
    /// A function that validates the data from a request. Throws a ``BadRequestDataError`` if it encounters one or multiple errors.
    static func validateRequest(data: inout RequestData) throws
    
    /// A function that decode the data to give an instance of this response and throws an error if an error was returned by YouTube's API.
    ///
    /// - Note: this function should only be overriden if you have to do special processing before getting the JSON from the data, for example this is the case with ``AutoCompletionResponse``. Make sure that you call the error handling method TODO: put it here if your version does not already process them.
    static func decodeData(data: Data) throws -> Self
    
    /// A function to extract the response from some JSON.
    static func decodeJSON(json: JSON) throws -> Self
    
    /// A function that throws the error from some JSON if there's one. It should be called when calling ``YouTubeResponse/decodeData(data:)``.
    static func checkForErrors(json: JSON) throws

    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    static func sendNonThrowingRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool?,
        result: @escaping @Sendable (Result<Self, Error>) -> ()
    )
    
    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendThrowingRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool?
    ) async throws -> Self
    
    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendNonThrowingRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool?
    ) async -> Result<Self, Error>
    
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use sendRequest(youtubeModel: YouTubeModel, data: RequestData, useCookies: Bool?, result: @escaping (Result<Self, Error>) -> ()) instead.") // safer and better to use the Result API instead of a tuple
    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool?,
        result: @escaping @Sendable (Self?, Error?) -> ()
    )

    /// A function to call the request of the given YouTubeResponse. For more informations see ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use sendRequest(youtubeModel: YouTubeModel, data: RequestData, useCookies: Bool?) async throws -> Self or sendRequest(youtubeModel: YouTubeModel, data: RequestData, useCookies: Bool?) async -> Result<Self, Error> instead.") // safer and better to use the throws or the result API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool?
    ) async -> (Self?, Error?)
}

public extension YouTubeResponse {
    
    static func sendNonThrowingRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool? = nil,
        result: @escaping @Sendable (Result<Self, Error>) -> ()
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
    static func sendThrowingRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool? = nil
    ) async throws -> Self {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Self, Error>) in
            self.sendNonThrowingRequest(youtubeModel: youtubeModel, data: data, useCookies: useCookies, result: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendNonThrowingRequest(
        youtubeModel: YouTubeModel,
        data: RequestData,
        useCookies: Bool? = nil
    ) async -> Result<Self, Error> {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Result<Self, Error>, Never>) in
            self.sendNonThrowingRequest(youtubeModel: youtubeModel, data: data, useCookies: useCookies, result: { result in
                continuation.resume(returning: result)
            })
        })
    }
    
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use sendRequest(youtubeModel: YouTubeModel, data: RequestData, useCookies: Bool?, result: @escaping (Result<Self, Error>) -> ()) instead.") // safer and better to use the Result API instead of a tuple
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool? = nil,
        result: @escaping @Sendable (Self?, Error?) -> ()
    ) {
        self.sendNonThrowingRequest(
            youtubeModel: youtubeModel,
            data: data,
            useCookies: useCookies,
            result: { returning in
                do {
                    result(try returning.get(), nil)
                } catch {
                    result(nil, error)
                }
            }
        )
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use sendRequest(youtubeModel: YouTubeModel, data: RequestData, useCookies: Bool?) async throws -> Self or sendRequest(youtubeModel: YouTubeModel, data: RequestData, useCookies: Bool?) async -> Result<Self, Error> instead.") // safer and better to use the throws or the result API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    static func sendRequest(
        youtubeModel: YouTubeModel,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool? = nil
    ) async -> (Self?, Error?) {
        do {
            return await (try self.sendThrowingRequest(youtubeModel: youtubeModel, data: data, useCookies: useCookies), nil)
        } catch {
            return (nil, error)
        }
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
    
    static func decodeData(data: Data) throws -> Self {
        let json = JSON(data)
        
        try self.checkForErrors(json: json)
        
        do {
            return try self.decodeJSON(json: json)
        } catch let error as ResponseExtractionError {
            throw error
        } catch {
            throw ResponseExtractionError(reponseType: Self.self, stepDescription: error.localizedDescription)
        }
    }
    
    static func checkForErrors(json: JSON) throws {
        if json["error"].exists() {
            throw NetworkError(code: json["error", "code"].intValue, message: json["error", "message"].stringValue)
        }
    }
}
