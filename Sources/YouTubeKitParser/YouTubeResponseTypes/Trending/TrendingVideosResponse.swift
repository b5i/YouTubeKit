//
//  TrendingVideosResponse.swift
//  
//
//  Created by Antoine Bollengier on 02.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation

public struct TrendingVideosResponse: YouTubeResponse {
    public static let headersType: HeaderTypes = .trendingVideosHeaders
    
    public static let parametersValidationList: ValidationList = [:]
    
    /// Dictionnary associating a category identifier (usually like "Music" or "Film" contained in the ``TrendingVideosResponse/requestParams`` as the dictionnary keys) with an array of videos (representing the trendig videos of the tab identifier). It can be seen as some cache for every type of category.
    ///
    /// You can also overwrite the content that it contains to another response by using (only the video arrays that are non-empty will overwrite):
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: TrendingVideosResponse = ...
    ///
    /// // Supposing myInstance.requestParams["MyIdentifier"] != nil (but can be an empty string)
    /// myInstance.getCategoryContent(forIdentifier: "MyIdentifier", youtubeModel: YTM) { result in
    ///     switch result {
    ///     case .success(let newInstance):
    ///         myInstance.mergeTrendingResponse(newInstance)
    ///     case .failure(let error):
    ///         // Deal with the error
    ///     }
    /// }
    /// ```
    public var categoriesContentsStore: [String : [YTVideo]] = [:]
    
    /// The category that is currently displayed (opened category on YouTube's side that contains the videos), by default, if no params (values of the ``TrendingVideosResponse/requestParams``) were given during the request (if you're using one of the `TrendingVideosResponse.sendRequest...` methods), the default "Trending" tab is returned.
    public var currentContentIdentifier: String? = nil
        
    /// Dictionnary of a string representing the params to send to get the RequestType from YouTube.
    public var requestParams: [String : String] = [:]
            
    public static func decodeJSON(json: JSON) -> TrendingVideosResponse {
        var toReturn = TrendingVideosResponse()
                
        /// Time to get the params to be able to make channel content requests.
        
        guard let tabsArray = json["contents", "twoColumnBrowseResultsRenderer", "tabs"].array else { return toReturn }
                        
        for tab in tabsArray {
            guard let tabName = tab["tabRenderer", "title"].string else { continue }
            
            toReturn.requestParams[tabName] = self.getParams(json: tab)
            
            guard tab["tabRenderer", "selected"].bool == true else { continue }
            
            var currentVideosArray: [YTVideo] = []
            
            toReturn.currentContentIdentifier = tabName
            
            for sectionContent in tab["tabRenderer", "content", "sectionListRenderer", "contents"].arrayValue {
                for itemSectionContents in sectionContent["itemSectionRenderer", "contents"].arrayValue {
                    for videoJSON in itemSectionContents["shelfRenderer", "content", "expandedShelfContentsRenderer", "items"].arrayValue {
                        guard let video = YTVideo.decodeJSON(json: videoJSON["videoRenderer"]) else { continue }
                        
                        currentVideosArray.append(video)
                    }
                }
            }
            
            toReturn.categoriesContentsStore[tabName] = currentVideosArray
        }
                        
        return toReturn
    }
    
    /// Get the trending videos for a certain category.
    ///
    /// To see an example usage, check ``TrendingVideosResponse/categoriesContentsStore``.
    public func getCategoryContent(forIdentifier identifier: String, youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<TrendingVideosResponse, Error>) -> ()) {
        guard
            let params = requestParams[identifier]
        else { result(.failure("Something between returnType or params haven't been added where it should, returnType in TrendingVideosResponse.requestTypes and params in TrendingVideosResponse.requestParams")); return }
        
        TrendingVideosResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: params], useCookies: useCookies, result: { trendingVideoResponse in
            result(trendingVideoResponse)
        })
    }
    
    /// Get the trending videos for a certain category.
    ///
    /// To see an example usage, check ``TrendingVideosResponse/categoriesContentsStore``.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func getCategoryContentThrowing(forIdentifier identifier: String, youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> TrendingVideosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<TrendingVideosResponse, Error>) in
            self.getCategoryContent(forIdentifier: identifier, youtubeModel: youtubeModel, useCookies: useCookies, result: { categoryContent in
                continuation.resume(with: categoryContent)
            })
        })
    }
    
    /// Merges another response to the current instance by overwriting the non-empty tabs and the currentContentIdentifier (if not nil) into it.
    public mutating func mergeTrendingResponse(_ otherResponse: TrendingVideosResponse) {
        for tab in otherResponse.categoriesContentsStore where !tab.value.isEmpty {
            self.categoriesContentsStore[tab.key] = otherResponse.categoriesContentsStore[tab.key]
            self.currentContentIdentifier = otherResponse.currentContentIdentifier ?? self.currentContentIdentifier
        }
    }
    
    /// Method that can be used to retrieve some request's params for a certain tab.
    /// - Parameter json: the JSON to be decoded.
    /// - Returns: The params that would be used to make the request for the category of the tab.
    private static func getParams(json: JSON) -> String {
        return json["tabRenderer", "endpoint", "browseEndpoint", "params"].stringValue
    }
}
