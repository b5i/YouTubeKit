//
//  RequestLog.swift
//  
//
//  Created by Antoine Bollengier on 06.03.2024.
//

import Foundation

/// A structure representing a log.
public struct RequestLog: Identifiable {
    public typealias RequestParameters = [HeadersList.AddQueryInfo.ContentTypes : String]
    
    /// The id of the log, can be used to remove it from ``RequestsLogger/logs`` using ``RequestsLogger/clearLogWithId(_:)-9itbf`` or ``RequestsLogger/clearLogsWithIds(_:)-24y22``.
    public let id = UUID()
    
    /// The date when the request has been finished (data has been received and processed).
    public let date = Date()
    
    /// The request parameters provided in ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)``.
    public let providedParameters: RequestParameters
    
    /// The request that has been sent over the network, can be nil if the request couldn't even be made, for example if one of the given RequestParameter didn't pass the verification tests.
    public let request: URLRequest?
    
    /// The raw data from the response.
    public let responseData: Data?
    
    /// The processed result or an error if there was one during the process.
    public let result: Result<any YouTubeResponse, Error>
    
    public init(providedParameters: RequestParameters, request: URLRequest?, responseData: Data?, result: Result<any YouTubeResponse, Error>) {
        self.providedParameters = providedParameters
        self.request = request
        self.responseData = responseData
        self.result = result
    }
}
