//
//  YouTubeHeaders.swift
//  
//
//  Created by Antoine Bollengier on 25.04.23.
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
        selectedLocale.components(separatedBy: "-")[0].lowercased()
    }
    
    /// Get the country code for ``YouTubeModel/selectedLocale``.
    ///
    /// e.g. fr-CH (where fr is the langague code for "french" and CH represents Switzerland as a country), it would return "ch".
    public var selectedLocaleCountryCode: String {
        let splittedLocale = selectedLocale.components(separatedBy: "-")
        guard splittedLocale.count > 1 else { return selectedLocaleLanguageCode }
        return splittedLocale[1].lowercased()
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
    
    /// Boolean indicating whether to include the ``YouTubeModel/cookies`` in the request or not, its value can be overwritten in ``YouTubeModel/sendRequest(responseType:data:useCookies:result:)`` with the `useCookies` parameter.
    public var alwaysUseCookies: Bool = false
    
    
    #if canImport(CommonCrypto)
    /// Generate the authentication hash from user's cookies required by YouTube.
    /// - Parameter cookies: user's authentification cookies.
    /// - Returns: A SAPISIDHASH cookie value, is generally used as the value for an HTTP header with name `Authorization`.
    public func generateSAPISIDHASHForCookies(_ cookies: String) -> String {
        let SAPISID = cookies.replacingOccurrences(of: "SAPISID=", with: "").components(separatedBy: ";")[0]
        let time = Int(Date().timeIntervalSince1970)
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
        result: @escaping (ResponseType?, Error?) -> ()
    ) {
        /// Get request headers.
        var headers = self.getHeaders(forType: ResponseType.headersType)
        
        guard !headers.isEmpty else { result(nil, "The headers from ID: \(ResponseType.headersType) are empty! (probably an error in the name or they are not added in YouTubeModel.shared.customHeadersFunctions)"); return}
        
        /// Check if it should append the cookies.
        if useCookies != false, ((useCookies ?? false) || alwaysUseCookies), cookies != "" {
            if let presentCookiesIndex = headers.headers.enumerated().first(where: {$0.element.name.lowercased() == "cookie"})?.offset {
                headers.headers[presentCookiesIndex].content += "; \(cookies)"
            } else {
                headers.headers.append(HeadersList.Header(name: "Cookie", content: cookies))
            }
            #if canImport(CommonCrypto)
            headers.headers.append(HeadersList.Header(name: "Authorization", content: generateSAPISIDHASHForCookies(cookies)))
            #endif
        }
        
        /// Create request
        let request = HeadersList.setHeadersAgentFor(
            content: headers,
            data: data
        )
        
        /// Create task with the request
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            /// Check if the task worked and gave back data.
            if let data = data {
                result(ResponseType.decodeData(data: data), error)
            } else {
                /// Exectued if the data was nil so there was probably an error.
                result(nil, error)
            }
        }
        
        /// Start it
        task.resume()
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
            return deletePlaylist()
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"graftUrl\":\"/results?search_query=",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"graftUrl\":\"/results?search_query=",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEwhat_to_watch\"}"
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
                    .init(index: 0, encode: true),
                    .init(index: 1, encode: true)
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230602.01.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"configInfo\":{},\"screenDensityFloat\":2,\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.5\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":120,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"graftUrl\":\"/watch?v=",
                    "&pp=YAHIAQE%3D\",\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"videoId\":\"",
                    "\",\"params\":\"YAHIAQE%3D\",\"playbackContext\":{\"contentPlaybackContext\":{\"vis\":5,\"splay\":false,\"autoCaptionsDefaultOn\":false,\"autonavState\":\"STATE_NONE\",\"html5Preference\":\"HTML5_PREF_WANTS\",\"signatureTimestamp\":19508,\"autoplay\":true,\"autonav\":true,\"referer\":\"https://www.youtube.com/\",\"lactMilliseconds\":\"-1\",\"watchAmbientModeContext\":{\"hasShownAmbientMode\":true,\"watchAmbientModeEnabled\":true}}},\"racyCheckOk\":false,\"contentCheckOk\":false}"
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
                    "{\"context\":{\"client\":{\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230120.00.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230120.00.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
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
                    "\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230120.00.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
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
                    "\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230120.00.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
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
                    "{\"context\":{\"client\":{\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230120.00.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\", \"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230201.01.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"deviceTheme\":\"DEVICE_THEME_SELECTED\"}"
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FElibrary\"}"
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"videoIds\":[\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20231016.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"title\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"action\":\"ACTION_MOVE_VIDEO_AFTER\",\"setVideoId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"setVideoId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"action\":\"ACTION_REMOVE_VIDEO_BY_VIDEO_ID\",\"removedVideoId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"actions\":[{\"addedVideoId\":\"",
                    "\",\"action\":\"ACTION_ADD_VIDEO\"}],\"playlistId\":\"",
                    "\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
    
    func deletePlaylist() -> HeadersList {
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230126.08.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"originalUrl\":\"https://www.youtube.com/watch?v=aZIQFIzI9Uo\",\"screenPixelDensity\":2,\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"consistencyTokenJars\":[{\"encryptedTokenJarContents\":\"\"}],\"internalExperimentFlags\":[]}},\"playlistId\":\"",
                    "\"}"
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230126.08.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"originalUrl\":\"https://www.youtube.com/watch?v=aZIQFIzI9Uo\",\"screenPixelDensity\":2,\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"consistencyTokenJars\":[{\"encryptedTokenJarContents\":\"\"}],\"internalExperimentFlags\":[]}},\"videoId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230126.08.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"originalUrl\":\"https://www.youtube.com/watch?v=aZIQFIzI9Uo\",\"screenPixelDensity\":2,\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"consistencyTokenJars\":[{\"encryptedTokenJarContents\":\"\"}],\"internalExperimentFlags\":[]}},\"continuation\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"target\":{\"videoId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"target\":{\"videoId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"target\":{\"videoId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"channelIds\":[\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"\(self.selectedLocaleLanguageCode)\",\"gl\":\"\(self.selectedLocaleCountryCode.uppercased())\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"channelIds\":[\"",
                    "\"],\"params\":\"CgIIAhgA\"}"
                ],
                parameters: [
                    .init(name: "prettyPrint", content: "false")
                ]
            )
        }
    }
}

extension String: Error {}
