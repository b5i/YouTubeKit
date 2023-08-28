//
//  YouTubeHeaders.swift
//  
//
//  Created by Antoine Bollengier on 25.04.23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Class managing headers.
public class YouTubeModel {
    
    public init() {}
    
    /// Set the locale you want to receive the call responses in.
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
    public var cookies: String?
    
    /// Send a request of type `ResponseType`to YouTube's API.
    /// - Parameters:
    ///   - responseType: Defines the request/response type, e.g.`SearchResponse.self`
    ///   - data: a dictionnary of possible data to add in the request's body. Is keyed with ``HeadersList/AddQueryInfo/ContentTypes``.
    ///   - result: Returns the optional ResponseType JSON processing and the optional error that could happen during the network request.
    public func sendRequest<ResponseType: YouTubeResponse>(
        responseType: ResponseType.Type,
        data: [HeadersList.AddQueryInfo.ContentTypes : String],
        result: @escaping (ResponseType?, Error?) -> ()
    ) {
        /// Get request headers.
        let headers = self.getHeaders(forType: ResponseType.headersType)
        
        guard !headers.isEmpty else { result(nil, "The headers from ID: \(ResponseType.headersType) are empty! (probably an error in the name or they are not added in YouTubeModel.shared.customHeadersFunctions)"); return}
        
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
                    "{\"context\":{\"client\":{\"hl\":\"fr\",\"gl\":\"FR\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"graftUrl\":\"/results?search_query=",
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
                    "{\"context\":{\"client\":{\"hl\":\"fr\",\"gl\":\"FR\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"graftUrl\":\"/results?search_query=",
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
                ],
                addQueryAfterParts: [
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"fr\",\"gl\":\"FR\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEwhat_to_watch\"}"
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
                    "{\"context\":{\"client\":{\"hl\":\"fr\",\"gl\":\"CH\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230120.00.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"",
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
                    "{\"context\":{\"client\":{\"hl\":\"fr\",\"gl\":\"CH\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230120.00.00\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"continuation\":\"",
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
}

extension String: Error {}
