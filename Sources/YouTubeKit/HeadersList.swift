//
//  HeadersList.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Main structure used to define headers, and convert them to a valid ``/Foundation/URLRequest``
public struct HeadersList: Codable {
    
    /// Used to check wether a custom headers is defined or not.
    public private(set) var isEmpty: Bool = false
    
    /// Get an empty instance of ``HeadersList``.
    public static func getEmtpy() -> HeadersList {
        HeadersList(
            isEmpty: true,
            url: URL(string: "https://www.example.com")!,
            method: .GET,
            headers: []
        )
    }
    
    /// URL of the call.
    public var url: URL
    
    /// Method of the call.
    public var method: HTTPMethod
    
    /// HTTP headers used in the call.
    public var headers: [Header]
    
    /// The body is usually splitted in multiple parts where a dynamic string has to be placed, setting the ``addQueryAfterParts`` lets you specify what to place between those parts of body and if it should encode it or not.
    ///
    /// Not required if the mode of the request is `GET`
    public var addQueryAfterParts: [AddQueryInfo]?
    
    /// Body of the request, can be splitted in multiple parts if the call use dynamic values inside it. See ``addQueryAfterParts`` and ``AddQueryInfo``
    ///
    /// Not required if the mode of the request is `GET`
    public var httpBody: [String]?
    
    /// Used to define parameters to add to the url.
    public var parameters: [ParameterToAdd]?
    
    /// Method of the request.
    public enum HTTPMethod: String, Codable {
        case GET, POST
    }
    
    /// Parameter to add to the call's URL.
    public struct ParameterToAdd: Codable {
        /// Name of the parameter.
        ///
        /// e.g. the parameter of name **v** would be added like this youtube.com?**v**=
        var name: String
        
        /// Content of the parameter, should be empty if a specialContent is specified.
        ///
        /// e.g. the parameter of content **example**  and name **v** would be added like this youtube.com?**v**=**example**
        var content: String
        
        /// Dynamic content of the parameter, is retrieved .
        var specialContent: ParameterToAddSpecialContent?
    }
    
    /// Lists the dynamic parameters possiblities.
    public enum ParameterToAddSpecialContent: String, Codable {
        
        /// Is defined with the `query` parameter of the function ``setHeadersAgentFor(content:data:)``.
        case query
    }


    /// Base structure of a HTTP header.
    ///
    /// e.g. the header **`Host:  www.youtube.com`** would be
    /// ```swift
    /// Header(
    ///     name: "Host",
    ///     content: "www.youtube.com"
    /// )
    /// ```
    public struct Header: Codable {
        /// Name of the header.
        var name: String
        
        /// Content of the header.
        var content: String
    }

    /// The body is usually splitted in multiple parts where a dynamic string has to be placed, adding a ``AddQueryInfo`` lets you specify what to place between those parts of body and if it should encode it or not.
    ///
    /// ```swift
    /// let body = ["you", "be"]
    /// AddQueryInfo(
    ///     index: 0,
    ///     encode: false,
    ///     content: .params
    /// )
    /// setHeadersAgentFor(params: "tu")
    /// ```
    /// would unify the body to `"youtube"`
    public struct AddQueryInfo: Codable {
        /// Index of the part body that will be before the content of the ``AddQueryInfo``.
        var index: Int
        
        /// Boolean specifying wether the content should be encoded in a url-safe way or not.
        var encode: Bool
        
        /// Content of the part to be added after the `index-th` of the body.
        var content: ContentTypes?
        
        /// All content of the posibilities are defined in their parameter of the function ``setHeadersAgentFor(content:data:)``
        ///
        /// You can know wether to define them or not in ``HeaderTypes``
        public enum ContentTypes: String, Codable, CaseIterable, RawRepresentable {
            case query
            
            /// Can be for example videoId, channelId, playlistId etc...
            case browseId
            case continuation
            case params
            case visitorData
            
            ///Those are used during the modification of a playlist
            case movingVideoID
            case videoBeforeID
            case playlistEditToken
        }
    }
    
    /// Creates an instance of ``URLRequest`` with given headers and parameters.
    /// - Parameters:
    ///   - content: List of headers and other informations in order to make the request.
    ///   - data: a dictionnary of possible data to add in the request's body. Is keyed with ``AddQueryInfo/ContentTypes``.
    /// - Returns: An ``URLRequest``built with the provided parameters and headers.
    public static func setHeadersAgentFor(
        content: HeadersList,
        data: [AddQueryInfo.ContentTypes : String]
    ) -> URLRequest {
        var url = content.url
        if content.parameters != nil {
            var parametersToAppend: [URLQueryItem] = []
            for parameter in content.parameters! {
                if parameter.specialContent != nil {
                    /// Check which specialContent to add
                    switch parameter.specialContent! {
                    case .query:
                        parametersToAppend.append(
                            URLQueryItem(
                                name: parameter.name,
                                value: "\(parameter.content)\(data[.query] ?? "")"
                                    .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                            )
                        )
                    }
                } else {
                    /// No specialContent specified, adding normal value
                    parametersToAppend.append(
                        URLQueryItem(
                            name: parameter.name,
                            value: parameter.content
                                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                        )
                    )
                }
            }
            url.append(queryItems: parametersToAppend)
        }
        var request = URLRequest(url: url)
        
        /// Looping each header and add it to the request
        for header in content.headers {
            request.setValue(header.content, forHTTPHeaderField: header.name)
        }
        
        /// Adding the body if the request is of type POST.
        if content.method == .POST {
            var body = ""
            for (index, partToBreak) in content.httpBody!.enumerated() {
                if content.addQueryAfterParts!.count > index {
                    /// Bool indicating if the data should be URLencoded or not
                    let encodeData = content.addQueryAfterParts![index].encode
                    
                    /// Get the type of the data that will be added to 
                    let dataTypeToAdd: AddQueryInfo.ContentTypes = content.addQueryAfterParts![index].content ?? .query
                    var dataToAdd: String = data[dataTypeToAdd] ?? ""
                    
                    if encodeData {
                        dataToAdd = dataToAdd.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    }
                    body = "\(body)\(partToBreak)\(dataToAdd)"
                } else {
                    body = "\(body)\(partToBreak)"
                }
            }
            request.httpBody = body.data(using: .utf8)
        }
        request.httpMethod = content.method.rawValue
        return request
    }
}
