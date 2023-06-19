//
//  SearchResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a search response.
public struct SearchResponse: YouTubeResponse {
    public static var headersType: HeaderTypes = .search
    
    /// String token that will be useful in case of a search continuation request ("load more" button).
    public var continuationToken: String = ""
    
    /// Results of the search.
    public var results: [any YTSearchResult] = []
    
    public static func decodeData(data: Data) -> SearchResponse {
        var searchResponse = SearchResponse()
        let json = JSON(data)
        ///Get the continuation token and actual search results among ads
        if let continuationJSON = json["contents"]["twoColumnSearchResultsRenderer"]["primaryContents"]["sectionListRenderer"]["contents"].array {
            ///Check wether each "contents" entry is
            for potentialContinuationRenderer in continuationJSON {
                if let continuationToken = potentialContinuationRenderer["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string {
                    ///1. A continuationItemRenderer that contains a continuation token
                    searchResponse.continuationToken = continuationToken
                } else if
                    let adArray = potentialContinuationRenderer["itemSectionRenderer"]["contents"].array,
                        adArray.count == 1,
                        adArray[0]["adSlotRenderer"]["enablePacfLoggingWeb"].bool != nil {
                    ///2. An advertising entry
                    continue
                } else if let resultsList = potentialContinuationRenderer["itemSectionRenderer"]["contents"].array {
                    ///3. The actual list of results
                    decodeResults(results: resultsList, searchResponse: &searchResponse)
                }
            }
        }
        
        return searchResponse
    }
    
    /// Decode each results in a JSON array and add them to a ``SearchResponse``.
    /// - Parameters:
    ///   - results: the JSON results.
    ///   - searchResponse: the ``SearchResponse`` where the decoded results will be appended.
    static func decodeResults(results: [JSON], searchResponse: inout SearchResponse) {
        for (index, resultElement) in results.enumerated() {
            guard var castedElement = getCastedResultElement(element: resultElement) else { continue } //continue if element type is not handled
            castedElement.id = index
            searchResponse.results.append(castedElement)
        }
    }
    
    /// Get the structure of a JSON element that is a query result.
    /// - Parameter element: JSON element that will be casted.
    /// - Returns: a ``YTSearchResult`` and nil if the given element wasn't conform to any ``YTSearchResult`` type.
    static func getCastedResultElement(element: JSON) -> (any YTSearchResult)? {
        if let castedElementType = getResultElementType(element: element) {
            do {
                return YTSearchResultType
                    .getDecodingStruct(forType: castedElementType)
                    .decodeJSON(data: try element[castedElementType.rawValue].rawData())
            } catch {}
        }
        return nil
    }
    
    /// Get the result type of a given JSON element.
    /// - Parameter element: the JSON where its the type has to be determined.
    /// - Returns: the type of the JSON element, nil if the element isn't conform to any ``YTSearchResult`` type.
    static func getResultElementType(element: JSON) -> YTSearchResultType? {
        for searchResultType in YTSearchResultType.allCases {
            if element[searchResultType.rawValue].dictionary != nil {
                return searchResultType
            }
        }
        return nil
    }
}
