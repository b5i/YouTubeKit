//
//  RequestLog.swift
//  
//
//  Created by Antoine Bollengier on 06.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

/// A protocol whose sole purpose is to have the ability to store the logs into an array in ``RequestsLogger/logs``.
public protocol GenericRequestLog {
    associatedtype LogType: YouTubeResponse
    typealias RequestParameters = [HeadersList.AddQueryInfo.ContentTypes : String]
    
    /// The id of the log, can be used to remove it from ``RequestsLogger/logs`` using ``RequestsLogger/clearLogWithId(_:)`` or ``RequestsLogger/clearLogsWithIds(_:)``.
    var id: UUID { get }
    
    /// The date when the request has been finished (data has been received and processed).
    var date: Date { get }
    
    /// The request parameters provided in ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    var providedParameters: RequestParameters { get }
    
    /// The request that has been sent over the network, can be nil if the request couldn't even be made, for example if one of the given RequestParameter didn't pass the verification tests.
    var request: URLRequest? { get }
    
    /// The raw data from the response.
    var responseData: Data? { get }
    
    /// The type of the request
    var expectedResultType: LogType.Type { get }
    
    /// The processed result or an error if there was one during the process.
    var result: Result<LogType, Error> { get }
 }

/// A structure representing a log.
public struct RequestLog<ResponseType: YouTubeResponse>: Identifiable, GenericRequestLog {
    public typealias LogType = ResponseType
    
    public let id = UUID()
    
    public let date = Date()
    
    public let providedParameters: RequestParameters
    
    public let request: URLRequest?
    
    public let responseData: Data?
    
    public let expectedResultType = LogType.self
    
    public let result: Result<LogType, Error>
    
    public init(providedParameters: RequestParameters, request: URLRequest?, responseData: Data?, result: Result<LogType, Error>) {
        self.providedParameters = providedParameters
        self.request = request
        self.responseData = responseData
        self.result = result
    }
}
