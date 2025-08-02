//
//  HeadersList.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Main structure used to define headers, and convert them to a valid `URLRequest`.
public struct HeadersList: Codable {
    
    public init(isEmpty: Bool = false, url: URL, method: HTTPMethod, headers: [Header], customHeaders: [String: AddQueryInfo.ContentTypes]? = nil, addQueryAfterParts: [AddQueryInfo]? = nil, httpBody: [String]? = nil, parameters: [ParameterToAdd]? = nil) {
        self.isEmpty = isEmpty
        self.url = url
        self.method = method
        self.headers = headers
        self.customHeaders = customHeaders
        self.addQueryAfterParts = addQueryAfterParts
        self.httpBody = httpBody
        self.parameters = parameters
    }
    
    /// Used to check whether a custom headers is defined or not.
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
    
    /// A dictionnary of custom headers to add, if it is already present in the ``headers``, the one in customHeaders is used.
    public var customHeaders: [String: AddQueryInfo.ContentTypes]?
    
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
        public init(name: String, content: String, specialContent: ParameterToAddSpecialContent? = nil) {
            self.name = name
            self.content = content
            self.specialContent = specialContent
        }
        
        /// Name of the parameter.
        ///
        /// e.g. the parameter of name **v** would be added like this youtube.com?**v**=
        public var name: String
        
        /// Content of the parameter, should be empty if a specialContent is specified.
        ///
        /// e.g. the parameter of content **example**  and name **v** would be added like this youtube.com?**v**=**example**
        public var content: String
        
        /// Dynamic content of the parameter, is retrieved .
        public var specialContent: ParameterToAddSpecialContent?
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
        public init(name: String, content: String) {
            self.name = name
            self.content = content
        }
        
        /// Name of the header.
        public var name: String
        
        /// Content of the header.
        public var content: String
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
        
        public init(index: Int, encode: Bool, content: ContentTypes? = nil) {
            self.index = index
            self.encode = encode
            self.content = content
        }
        
        /// Index of the part body that will be before the content of the ``AddQueryInfo``.
        public var index: Int
        
        /// Boolean specifying whether the content should be encoded in a url-safe way or not.
        public var encode: Bool
        
        /// Content of the part to be added after the `index-th` of the body.
        public var content: ContentTypes?
        
        /// All content of the posibilities are defined in their parameter of the function ``setHeadersAgentFor(content:data:)``
        ///
        /// You can know whether to define them or not in ``HeaderTypes``
        public enum ContentTypes: String, Codable, CaseIterable, RawRepresentable, Sendable {
            case query
            
            /// Can be for example videoId, channelId, playlistId etc...
            case browseId
            case continuation
            case params
            case visitorData
            case text
            
            /// Those are used during the modification of a playlist
            case movingVideoId
            case videoBeforeId
            case playlistEditToken
                        
            /// Used to completly replace the URL of the request, including the parameters that could potentially 
            case customURL
        }
    }
    
    /// Creates an instance of `URLRequest` with given headers and parameters.
    /// - Parameters:
    ///   - content: List of headers and other informations in order to make the request.
    ///   - data: a dictionnary of possible data to add in the request's body. Is keyed with ``AddQueryInfo/ContentTypes``.
    /// - Returns: An `URLRequest`built with the provided parameters and headers.
    public static func setHeadersAgentFor(
        content: HeadersList,
        data: YouTubeResponse.RequestData
    ) -> URLRequest {
        var url = URL(string: data[.customURL] ?? "") ?? content.url
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
                            )
                        )
                    }
                } else {
                    /// No specialContent specified, adding normal value
                    parametersToAppend.append(
                        URLQueryItem(
                            name: parameter.name,
                            value: parameter.content
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
                
        for (headerName, content) in content.customHeaders ?? [:] {
            request.setValue(data[content], forHTTPHeaderField: headerName)
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
