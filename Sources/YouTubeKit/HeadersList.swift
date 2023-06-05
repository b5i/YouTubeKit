//
//  HeadersList.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Main structure used to define headers, and convert them to a valid ``URLRequest``
public struct HeadersList: Codable {
    /// URL of the call.
    var url: URL
    
    /// Method of the call.
    var method: HTTPMethod
    
    /// HTTP headers used in the call.
    var headers: [Header]
    
    /// The body is usually splitted in multiple parts where a dynamic string has to be placed, setting the ``addQueryAfterParts`` lets you specify what to place between those parts of body and if it should encode it or not.
    ///
    /// Not required if the mode of the request is `GET`
    var addQueryAfterParts: [AddQueryInfo]?
    
    /// Body of the request, can be splitted in multiple parts if the call use dynamic values inside it. See ``addQueryAfterParts`` and ``AddQueryInfo``
    ///
    /// Not required if the mode of the request is `GET`
    var httpBody: [String]?
    
    /// Used to define parameters to add to the url.
    var parameters: [ParameterToAdd]?
    
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
        
        /// Is defined with the `query` parameter of the function ``setHeadersAgentFor(content:query:browseId:params:continuation:visitorData:movingVideoID:videoBeforeID:playlistEditToken:)``.
        case query
    }

    /// Base structure of a HTTP header.
    ///
    /// e.g. the header **`Host:  www.youtube.com`** would be
    /// ```
    /// Header(name: "Host", content: "www.youtube.com")
    /// ```
    public struct Header: Codable {
        /// Name of the header.
        var name: String
        
        /// Content of the header.
        var content: String
    }

    /// The body is usually splitted in multiple parts where a dynamic string has to be placed, adding a ``AddQueryInfo`` lets you specify what to place between those parts of body and if it should encode it or not.
    ///
    /// ```
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
        
        /// All content of the posibilities are defined in their parameter of the function ``setHeadersAgentFor(content:query:browseId:params:continuation:visitorData:movingVideoID:videoBeforeID:playlistEditToken:)``
        ///
        /// You can know wether to define them or not in ``HeaderTypes``
        public enum ContentTypes: Codable {
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
}
