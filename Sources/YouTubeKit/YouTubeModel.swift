//
//  YouTubeHeaders.swift
//
//
//  Created by Antoine Bollengier on 25.04.23.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation
#if canImport(CommonCrypto)
import CommonCrypto
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Class managing headers.
public class YouTubeModel {
    
    public init() {}
    
    /// Set the locale you want to receive the call responses in.
    ///
    /// Note: if authentication ``YouTubeModel/cookies`` are given, the response will not take `selectedLocale` in account but the account's selected locale.
    public var selectedLocale: String = Locale.preferredLanguages[0]
    
    /// Get the language code for ``YouTubeModel/selectedLocale``.
    ///
    /// e.g. fr-CH (where fr is the langague code for "french" and CH represents Switzerland as a country), it would return "fr".
    public var selectedLocaleLanguageCode: String {
        return selectedLocale.ytkFirstGroupMatch(for: "([^\\s|-]*)")?.lowercased() ?? ""
    }
    
    /// Get the country code for ``YouTubeModel/selectedLocale``.
    ///
    /// e.g. fr-CH (where fr is the langague code for "french" and CH represents Switzerland as a country), it would return "ch".
    public var selectedLocaleCountryCode: String {
        return selectedLocale.ytkFirstGroupMatch(for: "-([\\S]*)")?.lowercased() ?? self.selectedLocaleLanguageCode
    }
    
    /// Set Google account's cookies to perform user-related API calls.
    ///
    /// The required cookie fields are:
    /// - SAPISID
    /// - __Secure-1PAPISID
    /// - __Secure-1PSID
    ///
    /// The shape of the string should be:
    /// `"SAPISID=\(SAPISID); __Secure-1PAPISID=\(PAPISID); __Secure-1PSID=\(PSID1)"`
    public var cookies: String = ""
    
    /// A unique string given by YouTube to access some features.
    ///
    /// Can be obtained for example using a simple ``SearchResponse`` and accessing the ``SearchResponse/visitorData`` property.
    ///
    /// Usually takes the form of: `CgtmbWo5ZXBHTlNTVsiJtim9BjIIRgJDSNWDGgAgWw%3D%3D`
    ///
    /// If set, it will automatically added when needed to requests, otherwise you'll have to manually add it to the request's parameters.
    ///
    /// If you specify it for a request in its call, the value you specified will be used instead of this one.
    public var visitorData: String = ""
    
    /// Boolean indicating whether to include the ``YouTubeModel/cookies`` in the request or not, its value can be overwritten in ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)`` with the `useCookies` parameter.
    public var alwaysUseCookies: Bool = false
    
    /// The logger that will be used to store the information of the requests.
    public var logger: RequestsLogger? = nil
        
    #if canImport(CommonCrypto)
    /// Generate the authentication hash from user's cookies required by YouTube.
    /// - Parameter cookies: user's authentification cookies.
    /// - Returns: A SAPISIDHASH cookie value, is generally used as the value for an HTTP header with name `Authorization`.
    public func generateSAPISIDHASHForCookies(_ cookies: String, time: Int? = nil) -> String? {
        guard let SAPISID = cookies.ytkFirstGroupMatch(for: "SAPISID=([^\\s|;]*)") else { return nil }
        let time = time ?? Int(Date().timeIntervalSince1970)
        let data = Data("\(time) \(SAPISID) https://www.youtube.com".utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        let finalString = "SAPISIDHASH \(time)_\(hexBytes.joined())"
        return finalString
    }
    #endif
    
    /// Send a request of type `ResponseType` to YouTube's API.
    /// - Parameters:
    ///   - responseType: Defines the request/response type, e.g.`SearchResponse.self`
    ///   - data: a dictionnary of possible data to add in the request's body. Is keyed with ``HeadersList/AddQueryInfo/ContentTypes``.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - result: Returns the optional ResponseType JSON processing and the optional error that could happen during the network request.
    public func sendRequest<ResponseType: YouTubeResponse>(
        responseType: ResponseType.Type,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        useCookies: Bool? = nil,
        result: @escaping @Sendable (Result<ResponseType, Error>) -> ()
    ) {
        var data = data // make them mutable
        
        /// Get request headers.
        var headers = self.getHeaders(forType: ResponseType.headersType)
        
        guard !headers.isEmpty else { result(.failure("The headers from ID: \(ResponseType.headersType) are empty! (probably an error in the name or they are not added in YouTubeModel.shared.customHeadersFunctions)")); return}
        
        /// Check if it should append the cookies.
        if useCookies != false, ((useCookies ?? false) || alwaysUseCookies), cookies != "" {
            if let presentCookiesIndex = headers.headers.enumerated().first(where: {$0.element.name.lowercased() == "cookie"})?.offset {
                headers.headers[presentCookiesIndex].content += "; \(cookies)"
            } else {
                headers.headers.append(HeadersList.Header(name: "Cookie", content: cookies))
            }
#if canImport(CommonCrypto)
            if let sapisidHash = generateSAPISIDHASHForCookies(cookies) {
                headers.headers.append(HeadersList.Header(name: "Authorization", content: sapisidHash))
            }
#endif
        }
        
        do {
            if data[.visitorData] == nil, self.visitorData != "" {
                data[.visitorData] = self.visitorData
            }
            
            try ResponseType.validateRequest(data: &data)

            /// Create request
            let request: URLRequest = HeadersList.setHeadersAgentFor(
                content: headers,
                data: data
            )
            
            let data = data
            let endOfRequestHandler: @Sendable (Data?, Result<ResponseType, Error>) -> () = { [weak logger] responseData, responseResult in
                switch responseResult {
                case .success(let success):
                    logger?.addLog(RequestLog(providedParameters: data, request: request, responseData: responseData, result: .success(success)))
                case .failure(let error):
                    logger?.addLog(RequestLog<ResponseType>(providedParameters: data, request: request, responseData: responseData, result: .failure(error)))
                }
                result(responseResult)
            }
            
            /// Create task with the request
            let task = URLSession.shared.dataTask(with: request) { responseData, _, error in
                /// Check if the task worked and gave back data.
                if let responseData = responseData {
                    do {
                        let decodedResult = try ResponseType.decodeData(data: responseData)
                        
                        endOfRequestHandler(responseData, .success(decodedResult))
                    } catch let processingError {
                        endOfRequestHandler(responseData, .failure(processingError))
                    }
                } else if let error = error {
                    /// Exectued if the data was nil so there was probably an error.
                    endOfRequestHandler(responseData, .failure(error))
                } else {
                    endOfRequestHandler(responseData, .failure("Did not receive any error."))
                }
            }
            
            /// Start it
            task.resume()
        } catch {
            logger?.addLog(RequestLog<ResponseType>(providedParameters: data, request: nil, responseData: nil, result: .failure(error)))
            result(.failure(error))
        }
    }
    
    /// Custom headers that will be defined by the following methods.
    public var customHeaders: [HeaderTypes : HeadersList] = [:]
    
    /// Custom headers functions that generate ``HeadersList``.
    public var customHeadersFunctions: [String : () -> HeadersList] = [:]
    
    /// Add or modify custom headers.
    /// - Parameters:
    ///   - json: a json representation of the headers to modifiy.
    ///   - headersType: type of the header to be modified.
    public func replaceHeaders(withJSONData json: Data, headersType: HeaderTypes) throws {
        customHeaders[headersType] = try JSONDecoder().decode(HeadersList.self, from: json)
    }
    
    /// Add or modify custom headers.
    /// - Parameters:
    ///   - json: a json representation of the headers to modifiy.
    ///   - headersType: type of the header to be modified.
    public func replaceHeaders(withJSONString json: String, headersType: HeaderTypes) throws {
        customHeaders[headersType] = try JSONDecoder().decode(HeadersList.self, from: json.data(using: .utf8) ?? Data())
    }
    
    /// Add or modify custom headers.
    /// - Parameters:
    ///   - headers: headers to modify in the ``HeadersList`` format.
    ///   - headersType: type of the header to be modified.
    public func replaceHeaders(withHeaders headers: HeadersList, headersType: HeaderTypes) {
        customHeaders[headersType] = headers
    }
    
    /// Remove some custom headers.
    /// - Parameters:
    ///   - type: type of the header to be removed.
    public func removeCustomHeaders(ofType type: HeaderTypes) {
        customHeaders[type] = nil
    }
    
    /// Return headers from a specified type.
    /// - Parameter type: type of the demanded headers.
    /// - Returns: A ``HeadersList`` that can be used to make requests.
    public func getHeaders(forType type: HeaderTypes) -> HeadersList {
        switch type {
        case .home:
            return homeHeaders()
        case .search:
            return searchHeaders()
        case .restrictedSearch:
            return restrictedSearchHeaders()
        case .videoInfos:
            return getFormatsHeaders()
        case .videoInfosWithDownloadFormats:
            return getFormatAdaptatives()
        case .autoCompletion:
            return searchCompletionHeaders()
        case .channelHeaders:
            return getChannelVideosHeaders()
        case .playlistHeaders:
            return getPlaylistVideosHeaders()
        case .playlistContinuationHeaders:
            return getPlaylistVideosContinuationHeaders()
        case .homeVideosContinuationHeader:
            return getHomeVideosContinuationHeaders()
        case .searchContinuationHeaders:
            return searchContinuationHeaders()
        case .channelContinuationHeaders:
            return channelContinuationHeaders()
        case .userAccountHeaders:
            return userAccountInfosHeaders()
        case .usersLibraryHeaders:
            return usersLibraryHeaders()
        case .usersPlaylistsHeaders:
            return usersPlaylistsHeaders()
        case .usersAllPlaylistsHeaders:
             return usersAllPlaylistsHeaders()
        case .createPlaylistHeaders:
            return createPlaylistHeaders()
        case .moveVideoInPlaylistHeaders:
            return moveVideoInPlaylistHeaders()
        case .removeVideoFromPlaylistHeaders:
            return removeVideoFromPlaylistHeaders()
        case .removeVideoByIdFromPlaylistHeaders:
            return removeVideoByIdFromPlaylistHeaders()
        case .addVideoToPlaylistHeaders:
            return addVideoToPlaylistHeaders()
        case .deletePlaylistHeaders:
            return deletePlaylistHeaders()
        case .historyHeaders:
            return getHistoryHeaders()
        case .deleteVideoFromHistory:
            return deleteVideoFromHistoryHeaders()
        case .historyContinuationHeaders:
            return getHistoryContinuationHeaders()
        case .moreVideoInfosHeaders:
            return moreVideoInfos()
        case .fetchMoreRecommendedVideosHeaders:
            return fetchMoreRecommendedVideosHeaders()
        case .likeVideoHeaders:
            return likeVideoHeaders()
        case .dislikeVideoHeaders:
            return dislikeVideoHeaders()
        case .removeLikeStatusFromVideoHeaders:
            return removeLikeStatusFromVideoHeaders()
        case .subscribeToChannelHeaders:
            return subscribeToChannelHeaders()
        case .unsubscribeFromChannelHeaders:
            return unsubscribeFromChannelHeaders()
        case .videoCaptionsHeaders:
            return videoCaptionsHeaders()
        case .trendingVideosHeaders:
            return getTrendingVideosHeaders()
        case .usersSubscriptionsHeaders:
            return getUsersSubscriptionsHeaders()
        case .usersSubscriptionsContinuationHeaders:
            return getUsersSubscriptionsContinuationHeaders()
        case .usersSubscriptionsFeedHeaders:
            return getUsersSubscriptionsFeedHeaders()
        case .usersSubscriptionsFeedContinuationHeaders:
            return getUsersSubscriptionsFeedContinuationHeaders()
        case .videoCommentsHeaders, .videoCommentsContinuationHeaders:
            return getVideoCommentsHeaders()
        case .removeLikeCommentHeaders, .removeDislikeCommentHeaders, .dislikeCommentHeaders, .likeCommentHeaders, .removeCommentHeaders, .translateCommentHeaders:
            return likeActionsCommentHeaders(actionType: type)
        case .replyCommentHeaders:
            return replyCommentHeaders()
        case .editCommentHeaders:
            return editCommentHeaders()
        case .editReplyCommentHeaders:
            return editReplyCommentHeaders()
        case .createCommentHeaders:
            return createCommentHeaders()
        case .customHeaders(let stringIdentifier):
            if let headersGenerator = customHeadersFunctions[stringIdentifier] {
                return headersGenerator()
            } else {
                return HeadersList.getEmtpy()
            }
        }
    }
    
    // MARK: - Default Headers
    
    /// Get headers for a search request.
    /// - Returns: The headers for this request.
    func searchHeaders() -> HeadersList {
        if let headers = self.customHeaders[.search] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/search")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"graftUrl\":\"/results?search_query=",
                    "\"}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"query\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers for a restricted search request (items with Common Creative copyright).
    /// - Returns: The headers for this request.
    func restrictedSearchHeaders() -> HeadersList {
        if let headers = self.customHeaders[.restrictedSearch] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/search")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"graftUrl\":\"/results?search_query=",
                    "\"}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"query\":\"",
                    "\", \"params\": \"EgQQATAB\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the videos present in the home page of YouTube.
    /// - Returns: The headers for this request.
    func homeHeaders() -> HeadersList {
        if let headers = self.customHeaders[.home] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Connection", content: "keep-alive"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEwhat_to_watch\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the video's main HLS stream link.
    /// - Returns: The headers for this request.
    func getFormatsHeaders() -> HeadersList {
        if let headers = self.customHeaders[.videoInfos] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/player")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "com.google.ios.youtube/20.25.4 (iPhone16,2; U; CPU iOS 18_5_0 like Mac OS X;)"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com"),
                    .init(name: "X-Youtube-Client-Name", content: "5"),
                    .init(name: "X-Youtube-Client-Version", content: "20.25.4"),
                ],
                customHeaders: [
                    "X-Goog-Visitor-Id": .visitorData
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .query)
                ],
                httpBody: [
                    #"""
                    {
                      "contentCheckOk": true,
                      "context": {
                        "client": {
                          "clientName": "IOS",
                          "clientVersion": "20.25.4",
                          "deviceMake": "Apple",
                          "deviceModel": "iPhone16,2",
                          "hl": "\#(self.selectedLocaleLanguageCode)",
                          "osName": "iPhone",
                          "osVersion": "18.5.0.22F76",
                          "timeZone": "UTC",
                          "userAgent": "com.google.ios.youtube/20.25.4 (iPhone16,2; U; CPU iOS 18_5_0 like Mac OS X;)",
                          "utcOffsetMinutes": 0
                        }
                      },
                      "playbackContext": {
                        "contentPlaybackContext": {
                          "html5Preference": "HTML5_PREF_WANTS"
                        }
                      },
                      "racyCheckOk": true,
                      "videoId": "
                    """#,
                    #""}"#
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the video's download and stream formats, this version consumes more bandwidth but includes custom formats (more options).
    /// - Returns: The headers for this request.
    func getFormatAdaptatives() -> HeadersList {
        if let headers = self.customHeaders[.videoInfosWithDownloadFormats] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/watch")!,
                method: .GET,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                parameters: [
                    .init(name: "v", content: "", specialContent: .query),
                    .init(name: "bpctr", content: "9999999999"),
                    .init(name: "has_verified", content: "1")
                ]
            )
        }
    }
    
    /// Get headers for a search completion.
    /// - Returns: The headers for this request.
    func searchCompletionHeaders() -> HeadersList {
        if let headers = self.customHeaders[.autoCompletion] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://suggestqueries-clients6.youtube.com/complete/search")!,
                method: .GET,
                headers: [],
                parameters: [
                    .init(name: "client", content: "youtube"),
                    .init(name: "hl", content: self.selectedLocaleLanguageCode),
                    .init(name: "gl", content: self.selectedLocaleCountryCode),
                    .init(name: "gs_ri", content: "youtube"),
                    .init(name: "gs_rn", content: "64"),
                    .init(name: "ds", content: "yt"),
                    .init(name: "q", content: "", specialContent: .query)
                ]
            )
        }
    }
    
    /// Get headers to get the contents from a channel.
    /// - Returns: The headers for this request.
    func getChannelVideosHeaders() -> HeadersList {
        if let headers = self.customHeaders[.channelHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .browseId),
                    .init(index: 1, encode: false, content: .params)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"",
                    "\",\"params\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the contents from a playlist.
    /// - Returns: The headers for this request.
    func getPlaylistVideosHeaders() -> HeadersList {
        if let headers = self.customHeaders[.playlistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250312.04.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the continuation of a `getPlaylistVideosHeaders()` ("more results" button).
    /// - Returns: The headers for this request.
    func getPlaylistVideosContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.playlistContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the continuation of a `homeHeaders()` ("more results" button).
    /// - Returns: The headers for this request.
    func getHomeVideosContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.homeVideosContinuationHeader] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .visitorData),
                    .init(index: 1, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"visitorData\":\"",
                    "\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the continuation of a `homeHeaders()` ("more results" button).
    /// - Returns: The headers for this request.
    func searchContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.searchContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/search")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .visitorData),
                    .init(index: 1, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"visitorData\":\"",
                    "\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the continuation of a `searchHeaders()` ("more results" button).
    /// - Returns: The headers for this request.
    func channelContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.channelContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get a YouTube account's infos.
    func userAccountInfosHeaders() -> HeadersList {
        if let headers = self.customHeaders[.userAccountHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/account/account_menu")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\", \"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"deviceTheme\":\"DEVICE_THEME_SELECTED\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    /// Get a YouTube account's library.
    func usersLibraryHeaders() -> HeadersList {
        if let headers = self.customHeaders[.usersLibraryHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FElibrary\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get a all the playlists of a YouTube channel.
    func usersPlaylistsHeaders() -> HeadersList {
        if let headers = self.customHeaders[.usersPlaylistsHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEplaylist_aggregation\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get all playlists where a video could be added, also includes the info whether the video is already in the playlist or not.
    func usersAllPlaylistsHeaders() -> HeadersList {
        if let headers = self.customHeaders[.usersAllPlaylistsHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/playlist/get_add_to_playlist")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"videoIds\":[\"",
                    "\"],\"excludeWatchLater\":false}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Create a playlist in the user's library.
    func createPlaylistHeaders() -> HeadersList {
        if let headers = self.customHeaders[.createPlaylistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/playlist/create")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .query),
                    .init(index: 1, encode: false, content: .params),
                    .init(index: 2, encode: false, content: .movingVideoId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"title\":\"",
                    "\",\"privacyStatus\":\"",
                    "\",\"videoIds\":[\"",
                    "\"]}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Move a video in a playlist.
    func moveVideoInPlaylistHeaders() -> HeadersList {
        if let headers = self.customHeaders[.moveVideoInPlaylistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse/edit_playlist")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .movingVideoId),
                    .init(index: 1, encode: false, content: .videoBeforeId),
                    .init(index: 2, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"action\":\"ACTION_MOVE_VIDEO_AFTER\",\"setVideoId\":\"",
                    "\",\"movedSetVideoIdPredecessor\":\"",
                    "\"}],\"playlistId\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func removeVideoFromPlaylistHeaders() -> HeadersList {
        if let headers = self.customHeaders[.removeVideoFromPlaylistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse/edit_playlist")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .movingVideoId),
                    .init(index: 1, encode: false, content: .playlistEditToken),
                    .init(index: 2, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"setVideoId\":\"",
                    "\",\"action\":\"ACTION_REMOVE_VIDEO\"}],\"params\":\"",
                    "\",\"playlistId\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func removeVideoByIdFromPlaylistHeaders() -> HeadersList {
        if let headers = self.customHeaders[.removeVideoByIdFromPlaylistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse/edit_playlist")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .movingVideoId),
                    .init(index: 1, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"action\":\"ACTION_REMOVE_VIDEO_BY_VIDEO_ID\",\"removedVideoId\":\"",
                    "\"}],\"playlistId\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func addVideoToPlaylistHeaders() -> HeadersList {
        if let headers = self.customHeaders[.addVideoToPlaylistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse/edit_playlist")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .movingVideoId),
                    .init(index: 1, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"addedVideoId\":\"",
                    "\",\"action\":\"ACTION_ADD_VIDEO\"}],\"playlistId\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func deletePlaylistHeaders() -> HeadersList {
        if let headers = self.customHeaders[.deletePlaylistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/playlist/delete")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"originalUrl\":\"https://www.youtube.com/watch?v=aZIQFIzI9Uo\",\"screenPixelDensity\":2,\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"consistencyTokenJars\":[{\"encryptedTokenJarContents\":\"\"}],\"internalExperimentFlags\":[]}},\"playlistId\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the contents from a playlist.
    /// - Returns: The headers for this request.
    func getHistoryHeaders() -> HeadersList {
        if let headers = self.customHeaders[.historyHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [.init(index: 0, encode: true)],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEhistory\", \"query\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the continuation of a `getHistoryContinuationHeaders()` ("more results" button).
    /// - Returns: The headers for this request.
    func getHistoryContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.historyContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func deleteVideoFromHistoryHeaders() -> HeadersList {
        if let headers = self.customHeaders[.deleteVideoFromHistory] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/feedback")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .movingVideoId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"originalUrl\":\"https://www.youtube.com/watch?v=aZIQFIzI9Uo\",\"screenPixelDensity\":2,\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"consistencyTokenJars\":[{\"encryptedTokenJarContents\":\"\"}],\"internalExperimentFlags\":[]}},\"feedbackTokens\":[\"",
                    "\"],\"isFeedbackTokenUnencrypted\":false,\"shouldMerge\":false}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func moreVideoInfos() -> HeadersList {
        if let headers = self.customHeaders[.moreVideoInfosHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/next")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: true)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"originalUrl\":\"https://www.youtube.com/watch?v=aZIQFIzI9Uo\",\"screenPixelDensity\":2,\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"consistencyTokenJars\":[{\"encryptedTokenJarContents\":\"\"}],\"internalExperimentFlags\":[]}},\"videoId\":\"",
                    "\",\"racyCheckOk\":false,\"contentCheckOk\":false,\"autonavState\":\"STATE_NONE\",\"playbackContext\":{\"vis\":0,\"lactMilliseconds\":\"-1\"},\"captionsRequested\":false}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func fetchMoreRecommendedVideosHeaders() -> HeadersList {
        if let headers = self.customHeaders[.fetchMoreRecommendedVideosHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/next")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"originalUrl\":\"https://www.youtube.com/watch?v=aZIQFIzI9Uo\",\"screenPixelDensity\":2,\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"consistencyTokenJars\":[{\"encryptedTokenJarContents\":\"\"}],\"internalExperimentFlags\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func likeVideoHeaders() -> HeadersList {
        if let headers = self.customHeaders[.likeVideoHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/like/like")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: true)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"target\":{\"videoId\":\"",
                    "\"}}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func dislikeVideoHeaders() -> HeadersList {
        if let headers = self.customHeaders[.dislikeVideoHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/like/dislike")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: true)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"target\":{\"videoId\":\"",
                    "\"}}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func removeLikeStatusFromVideoHeaders() -> HeadersList {
        if let headers = self.customHeaders[.removeLikeStatusFromVideoHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/like/removelike")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: true)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"target\":{\"videoId\":\"",
                    "\"}}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func subscribeToChannelHeaders() -> HeadersList {
        if let headers = self.customHeaders[.subscribeToChannelHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/subscription/subscribe")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"channelIds\":[\"",
                    "\"],\"params\":\"EgIIAhgA\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func unsubscribeFromChannelHeaders() -> HeadersList {
        if let headers = self.customHeaders[.unsubscribeFromChannelHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/subscription/unsubscribe")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .browseId)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"channelIds\":[\"",
                    "\"],\"params\":\"CgIIAhgA\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func videoCaptionsHeaders() -> HeadersList {
        if let headers = self.customHeaders[.videoCaptionsHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/")!, // will be overriden by the customURL option
                method: .GET,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/xml"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                parameters: []
            )
        }
    }
    
    /// Get headers to get the contents from the Trending menu.
    /// - Returns: The headers for this request.
    func getTrendingVideosHeaders() -> HeadersList {
        if let headers = self.customHeaders[.trendingVideosHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .params)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEtrending\",\"params\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }

    /// Get headers to get the user's subscriptions
    /// - Returns: The headers for this request.
    func getUsersSubscriptionsHeaders() -> HeadersList {
        if let headers = self.customHeaders[.usersSubscriptionsHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEchannels\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the continuation of a `getUsersSubscriptionsHeaders()` ("more results" button).
    /// - Returns: The headers for this request.
    func getUsersSubscriptionsContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.usersSubscriptionsContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the user's subscriptions
    /// - Returns: The headers for this request.
    func getUsersSubscriptionsFeedHeaders() -> HeadersList {
        if let headers = self.customHeaders[.usersSubscriptionsFeedHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEsubscriptions\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    /// Get headers to get the continuation of a `getUsersSubscriptionsHeaders()` ("more results" button).
    /// - Returns: The headers for this request.
    func getUsersSubscriptionsFeedContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.usersSubscriptionsFeedContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func getVideoCommentsHeaders() -> HeadersList {
        if let headers = self.customHeaders[.videoCommentsHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/next")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .continuation)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func likeActionsCommentHeaders(actionType: HeaderTypes) -> HeadersList {
        if let headers = self.customHeaders[actionType] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/comment/perform_comment_action")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .params)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[\"",
                    "\"]}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func replyCommentHeaders() -> HeadersList {
        if let headers = self.customHeaders[.replyCommentHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/comment/create_comment_reply")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .params),
                    .init(index: 1, encode: false, content: .text)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"createReplyParams\":\"",
                    "\", \"commentText\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func editCommentHeaders() -> HeadersList {
        if let headers = self.customHeaders[.editCommentHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/comment/update_comment")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .text),
                    .init(index: 1, encode: false, content: .params)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"commentText\":\"",
                    "\", \"updateCommentParams\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func editReplyCommentHeaders() -> HeadersList {
        if let headers = self.customHeaders[.editCommentHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/comment/update_comment_reply")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .text),
                    .init(index: 1, encode: false, content: .params)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"replyText\":\"",
                    "\", \"updateReplyParams\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func createCommentHeaders() -> HeadersList {
        if let headers = self.customHeaders[.createCommentHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/comment/create_comment")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com")
                ],
                addQueryAfterParts: [
                    .init(index: 0, encode: false, content: .params),
                    .init(index: 1, encode: false, content: .text)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250717.02.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"createCommentParams\":\"",
                    "\", \"commentText\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
}

#if swift(>=6.0)
extension String: @retroactive LocalizedError {
    public var errorDescription: String? { self }
}
#else
extension String: LocalizedError {
    public var errorDescription: String? { self }
}
#endif
