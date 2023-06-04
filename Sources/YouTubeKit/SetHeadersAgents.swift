//
//  SetHeadersAgents.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation


/// Creates an instance of ``URLRequest`` with given headers and parameters.
/// - Parameters:
///   - content: List of headers and other informations in order to make the request.
///   - query: See ``HeaderTypes``.
///   - browseId: See ``HeaderTypes``.
///   - params: See ``HeaderTypes``.
///   - continuation: See ``HeaderTypes``.
///   - visitorData: See ``HeaderTypes``.
///   - movingVideoID: See ``HeaderTypes``.
///   - videoBeforeID: See ``HeaderTypes``.
///   - playlistEditToken: See ``HeaderTypes``.
/// - Returns: An ``URLRequest``built with the provided parameters and headers.
public func setHeadersAgentFor(
    content: HeadersList,
    query: String = "",
    browseId: String = "",
    params: String = "",
    continuation: String = "",
    visitorData: String = "",
    movingVideoID: String = "",
    videoBeforeID: String = "",
    playlistEditToken: String = ""
) -> URLRequest {
    var url = content.url
    if content.parameters != nil {
        var parametersToAppend = [URLQueryItem]()
        for parameter in content.parameters! {
            if parameter.specialContent != nil {
                switch parameter.specialContent! {
                case .query:
                        parametersToAppend.append(URLQueryItem(name: parameter.name, value: "\(parameter.content)\(query)"))
                }
            } else {
                parametersToAppend.append(URLQueryItem(name: parameter.name, value: parameter.content))
            }
        }
        url.append(queryItems: parametersToAppend)
    }
    var request = URLRequest(url: url)
    for header in content.headers {
        request.setValue(header.content, forHTTPHeaderField: header.name)
    }
    if content.method == .POST {
        var body = ""
        for (index, partToBreak) in content.httpBody!.enumerated() {
            if (content.addQueryAfterParts!.contains(where: {$0.index == index && $0.encode})) {
                switch content.addQueryAfterParts![index].content {
                case .browseId:
                    body = "\(body)\(partToBreak)\(browseId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                case .params:
                    body = "\(body)\(partToBreak)\(params.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                case .continuation:
                    body = "\(body)\(partToBreak)\(continuation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                case .visitorData:
                    body = "\(body)\(partToBreak)\(visitorData.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                case .movingVideoID:
                    body = "\(body)\(partToBreak)\(movingVideoID.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                case .videoBeforeID:
                    body = "\(body)\(partToBreak)\(videoBeforeID.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                case .playlistEditToken:
                    body = "\(body)\(partToBreak)\(playlistEditToken.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                default:
                    body = "\(body)\(partToBreak)\(query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                }
            } else if (content.addQueryAfterParts!.contains(where: {$0.index == index})) {
                switch content.addQueryAfterParts![index].content {
                case .browseId:
                    body = "\(body)\(partToBreak)\(browseId)"
                case .params:
                    body = "\(body)\(partToBreak)\(params)"
                case .continuation:
                    body = "\(body)\(partToBreak)\(continuation)"
                case .visitorData:
                    body = "\(body)\(partToBreak)\(visitorData)"
                case .movingVideoID:
                    body = "\(body)\(partToBreak)\(movingVideoID)"
                case .videoBeforeID:
                    body = "\(body)\(partToBreak)\(videoBeforeID)"
                case .playlistEditToken:
                    body = "\(body)\(partToBreak)\(playlistEditToken)"
                default:
                    body = "\(body)\(partToBreak)\(query)"
                }
            } else {
                body = "\(body)\(partToBreak)"
            }
        }
        request.httpBody = body.data(using: .utf8)
    }
    request.httpMethod = content.method.rawValue
    return request
}

public extension URL {
    //adapted from https://stackoverflow.com/questions/34060754/how-can-i-build-a-url-with-query-parameters-containing-multiple-values-for-the-s
    mutating func append(queryItems queryItemsToAdd: [URLQueryItem]) {
        guard var urlComponents = URLComponents(string: self.absoluteString) else { return }
        
        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        
        // Append the new query item in the existing query items array
        queryItems.append(contentsOf: queryItemsToAdd)
        
        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems
        
        // Returns the url from new url components
        self = urlComponents.url!
    }
}
