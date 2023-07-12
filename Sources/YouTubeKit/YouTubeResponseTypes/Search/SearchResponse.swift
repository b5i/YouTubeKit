//
//  SearchResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a search response.
public struct SearchResponse: ResultsResponse {
    public static var headersType: HeaderTypes = .search
    
    /// String token that will be useful in case of a search continuation request ("load more" button).
    public var continuationToken: String?
    
    /// Results of the search.
    public var results: [any YTSearchResult] = []
    
    /// String token that will be useful in case of a search continuation request (authenticate the continuation request).
    public var visitorData: String?
    
    public static func decodeData(data: Data) -> SearchResponse {
        var searchResponse = SearchResponse()
        let json = JSON(data)
        
        /// Getting visitorData
        searchResponse.visitorData = json["responseContext"]["visitorData"].stringValue
        
        ///Get the continuation token and actual search results among ads
        if let relevantContentJSON = json["contents"]["twoColumnSearchResultsRenderer"]["primaryContents"]["sectionListRenderer"]["contents"].array {
            ///Check wether each "contents" entry is
            for potentialContinuationRenderer in relevantContentJSON {
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
                    searchResponse.results.append(contentsOf: decodedResults(results: resultsList))
                }
            }
        }
        
        return searchResponse
    }
    
    /// Decode each results in a JSON array return them to, used to decode ``SearchResponse`` and ``SearchResponse/Continuation`` contents.
    /// - Parameters:
    ///   - results: the JSON results.
    ///   - Returns: an array of ``YTSearchResult``.
    static func decodedResults(results: [JSON]) -> [any YTSearchResult] {
        var toReturn: [any YTSearchResult] = []
        for (index, resultElement) in results.enumerated() {
            guard var castedElement = getCastedResultElement(element: resultElement) else { continue } //continue if element type is not handled
            castedElement.id = index
            toReturn.append(castedElement)
        }
        return toReturn
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
    
    /// Struct representing the ``SearchResponse`` but restricted to Creative Commons copyrighted videos.
    public struct Restricted: YouTubeResponse {
        public static var headersType: HeaderTypes = .restrictedSearch
        
        /// String token that will be useful in case of a search continuation request ("load more" button).
        public var continuationToken: String = ""
        
        /// Results of the search.
        public var results: [any YTSearchResult] = []
        
        /// String token that will be useful in case of a search continuation request (authenticate the continuation request).
        public var visitorData: String = ""
        
        public static func decodeData(data: Data) -> SearchResponse.Restricted {
            var searchResponse = SearchResponse.Restricted()
            let json = JSON(data)
            
            /// Getting visitorData
            searchResponse.visitorData = json["responseContext"]["visitorData"].stringValue
            
            ///Get the continuation token and actual search results among ads
            if let relevantContentJSON = json["contents"]["twoColumnSearchResultsRenderer"]["primaryContents"]["sectionListRenderer"]["contents"].array {
                ///Check wether each "contents" entry is
                for potentialContinuationRenderer in relevantContentJSON {
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
                        searchResponse.results.append(contentsOf: decodedResults(results: resultsList))
                    }
                }
            }
            
            return searchResponse
        }
    }
    
    /// Merge a ``SearchResponse/Continuation`` to this instance of ``SearchResponse``.
    /// - Parameter continuation: the ``SearchResponse/Continuation`` that will be merged.
    public mutating func mergeContinuation(_ continuation: Continuation) {
        self.continuationToken = continuation.continuationToken
        self.results.append(contentsOf: continuation.results)
    }
    
    /// Struct representing the continuation response of a ``SearchResponse`` ("load more results" button).
    ///
    /// You could for example merge the continuation results with the base ``SearchResponse`` ones like this:
    /// ```swift
    /// let mySearchResponse: SearchResponse = ...
    /// let mySearchResponseContinuation: SearchResponse.Continuation = ...
    /// mySearchResponse.mergeContinuation(mySearchResponseContinuation)
    /// ```
    public struct Continuation: ResultsContinuationResponse {
        public static var headersType: HeaderTypes = .searchContinuationHeaders
        
        /// String token that will be useful in case of a search continuation request ("load more" button).
        public var continuationToken: String? = nil
        
        /// Results of the continuation search.
        public var results: [any YTSearchResult] = []
        
        public static func decodeData(data: Data) -> SearchResponse.Continuation {
            var continuationResponse = SearchResponse.Continuation()
            let json = JSON(data)
            
            ///Get the continuation token and actual search results among ads
            if let relevantContentJSON = json["onResponseReceivedCommands"][0]["appendContinuationItemsAction"]["continuationItems"].array {
                ///Check wether each "contents" entry is
                for potentialContinuationRenderer in relevantContentJSON {
                    if let continuationToken = potentialContinuationRenderer["continuationItemRenderer"]["continuationEndpoint"]["continuationCommand"]["token"].string {
                        ///1. A continuationItemRenderer that contains a continuation token
                        continuationResponse.continuationToken = continuationToken
                    } else if
                        let adArray = potentialContinuationRenderer["itemSectionRenderer"]["contents"].array,
                            adArray.count == 1,
                            adArray[0]["adSlotRenderer"]["enablePacfLoggingWeb"].bool != nil {
                        ///2. An advertising entry
                        continue
                    } else if let resultsList = potentialContinuationRenderer["itemSectionRenderer"]["contents"].array {
                        ///3. The actual list of results
                        continuationResponse.results.append(contentsOf: decodedResults(results: resultsList))
                    }
                }
            }
            
            return continuationResponse
        }
    }
}
