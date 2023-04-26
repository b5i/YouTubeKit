//
//  RequestHeaders.swift
//  
//
//  Created by Antoine Bollengier on 25.04.23.
//

import Foundation

public class HeadersModel {
    public static let shared = HeadersModel()
    
    public var selectedLocale: String = Locale.preferredLanguages[0]
}



public struct HeadersList: Codable {
    /// The url that the
    ///
    ///
    /// When you implement a `Text`, you must be sure that is will stay visible whether choice your user do.
    /// The `textColor` attribute provides the right color your `Text` has to be.
    ///
    ///     struct MyView: View {
    ///         @Environment(\.colorScheme) var colorScheme
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///             .foregroundColor(colorScheme.textColor)
    ///         }
    ///     }
    var url: URL
    
    var method: HTTPMethod
    var headers: [Header]
    var addQueryAfterParts: [AddQueryInfo]
    var httpBody: [String]
    var parameters: [ParameterToAdd]
    
    public enum HTTPMethod: String, Codable {
        case GET, POST
    }
    
    public struct ParameterToAdd: Codable {
        var name: String
        var content: String
        var specialContent: ParameterToAddSpecialContent
    }

    public enum ParameterToAddSpecialContent: String, Codable {
        case query
    }

    public struct Header: Codable {
        var name: String
        var content: String
    }

    public struct AddQueryInfo: Codable {
        var index: Int
        var encode: Bool
    }
}

public enum HeaderTypes {
    case search, searchContinuation, searchCompletion, format
}

 struct Headers {
    static let headers: [HeaderTypes : HeadersList] = [:]
    
    static var searchHeaders: HeadersList {
        get {
            HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/search?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale),fr;q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Connection", content: "keep-alive"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Youtube-Client-Name", content: "1"),
                    .init(name: "Priority", content: "u=3, i"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: true),
                    .init(index: 1, encode: false)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"fr\",\"gl\":\"FR\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"graftUrl\":\"/results?search_query=",
                    "\"}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"query\":\"",
                    "\"}"
                ],
                parameters: []
            )
        }
    }
}
