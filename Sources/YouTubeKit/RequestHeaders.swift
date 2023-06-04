//
//  RequestHeaders.swift
//  
//
//  Created by Antoine Bollengier on 25.04.23.
//

import Foundation

public class HeadersModel {
    public static let shared = HeadersModel()
    
    public var selectedLocale: String = Locale.preferredLanguages[0]
}



public struct HeadersList: Codable {
    var url: URL
    
    var method: HTTPMethod
    var headers: [Header]
    var addQueryAfterParts: [AddQueryInfo]?
    var httpBody: [String]?
    var parameters: [ParameterToAdd]?
    
    public enum HTTPMethod: String, Codable {
        case GET, POST
    }
    
    public struct ParameterToAdd: Codable {
        var name: String
        var content: String
        var specialContent: ParameterToAddSpecialContent?
    }

    public enum ParameterToAddSpecialContent: String, Codable {
        case query
    }

    public struct Header: Codable {
        var name: String
        var content: String
    }

    public struct AddQueryInfo: Codable {
        var index: Int
        var encode: Bool
        var content: ContentTypes?
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

/// List of possibles requests where you can send to YouTube
public enum HeaderTypes: String {
    /// Get home menu videos.
    case home
    
    /// Get search results.
    /// - Parameter query: Search query
    case search
    
    /// Get search results that have a Creative Commons license.
    /// - Parameter query: Search query
    case restrictedSearch
    
    /// Get streaming infos for a video.
    /// - Parameter query: Video's ID
    case format
    
    /// Get streaming infos for a video, including adaptative formats.
    /// - Parameter query: Video's ID
    case formatAdaptative
    
    /// Get autocompletion for query.
    /// - Parameter query: Search query
    case autoCompletion
    
    /// Get channel infos.
    /// - Parameter browseId: Channel's ID
    /// - Parameter params: The operation param (videos, shorts, directs, playlists)
    case channelHeaders
    
    /// Get playlist's videos.
    /// - Parameter browseId: Playlist's ID
    case playlistHeaders
    
    /// Get playlist's videos (continuation).
    /// - Parameter continuation: Playlist's continuation token
    case playlistContinuationHeaders
    
    /// Get home menu's videos (continuation).
    /// - Parameter continuation: Home menu's continuation token
    case homeVideosContinuationHeader
    
    /// Get search's results (continuation).
    /// - Parameter visitorData: The visitorData token
    /// - Parameter continuation: Search's continuation token
    case searchContinuationHeaders
    
    /// Get channel's results (continuation).
    /// - Parameter continuation: Channel query's continuation token
    case channelContinuationHeaders
}

public class YouTubeHeaders {
    
    public static let shared = YouTubeHeaders()
    
    public static let headers: [HeaderTypes : HeadersList] = [:]
    
    var customHeaders: [HeaderTypes : HeadersList] = [:]
    
    
    public func replaceHeaders(withJSONData json: Data, headersType: HeaderTypes) throws {
        customHeaders[headersType] = try JSONDecoder().decode(HeadersList.self, from: json)
    }
    
    public func replaceHeaders(withJSONString json: String, headersType: HeaderTypes) throws {
        customHeaders[headersType] = try JSONDecoder().decode(HeadersList.self, from: json.data(using: .utf8) ?? Data())
    }
    
    public func replaceHeaders(withHeaders headers: HeadersList, headersType: HeaderTypes) {
        customHeaders[headersType] = headers
    }
    
    public func removeCustomHeaders(ofType type: HeaderTypes) {
        customHeaders[type] = nil
    }
    
    public func getHeaders(forType type: HeaderTypes) -> HeadersList {
        switch type {
        case .home:
            return homeHeaders()
        case .search:
            return searchHeaders()
        case .restrictedSearch:
            return restrictedSearchHeaders()
        case .format:
            return getFormatsHeaders()
        case .formatAdaptative:
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
        }
    }
    
    // MARK: - Default Headers
    
    func searchHeaders() -> HeadersList {
        if let headers = self.customHeaders[.search] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/search?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
    
    func restrictedSearchHeaders() -> HeadersList {
        if let headers = self.customHeaders[.restrictedSearch] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/search?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
    
    func homeHeaders() -> HeadersList {
        if let headers = self.customHeaders[.home] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Connection", content: "keep-alive"),
                    .init(name: "Content-Type", content: "application/json"),
                ],
                addQueryAfterParts: [
                ],
                httpBody: [
                    "{\"context\":{\"client\":{\"hl\":\"fr\",\"gl\":\"FR\",\"deviceMake\":\"Apple\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20221220.09.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.2\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":60,\"mainAppWebInfo\":{\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"browseId\":\"FEwhat_to_watch\"}"
                ]
            )
        }
    }
    
    func getFormatsHeaders() -> HeadersList {
        if let headers = self.customHeaders[.format] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/player?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
    
    func getFormatAdaptatives() -> HeadersList {
        if let headers = self.customHeaders[.formatAdaptative] {
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
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "X-Origin", content: "https://www.youtube.com"),
                    .init(name: "Cookie", content: "CONSENT=YES+cb.20210328-17-p0.en+FX+841")
                ],
                parameters: [
                    .init(name: "v", content: "", specialContent: .query),
                    .init(name: "bpctr", content: "9999999999"),
                    .init(name: "has_verified", content: "1")
                ]
            )
        }
    }
    
    func searchCompletionHeaders() -> HeadersList {
        if let headers = self.customHeaders[.autoCompletion] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://suggestqueries-clients6.youtube.com/complete/search?client=youtube&hl=fr&gl=fr&gs_ri=youtube&ds=yt")!,
                method: .GET,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
                    .init(name: "Origin", content: "https://www.youtube.com/"),
                    .init(name: "Referer", content: "https://www.youtube.com/"),
                    .init(name: "Content-Type", content: "application/json"),
                    .init(name: "Priority", content: "u=1, i")
                ],
                parameters: [
                    .init(name: "client", content: "youtube"),
                    .init(name: "hl", content: HeadersModel.shared.selectedLocale.lowercased().components(separatedBy: "-")[0]), //e.g.: "fr-FR" would become "fr"
                    .init(name: "gl", content: HeadersModel.shared.selectedLocale.lowercased().components(separatedBy: "-")[0]),
                    .init(name: "gs_ri", content: "youtube"),
                    .init(name: "ds", content: "yt"),
                    .init(name: "q", content: "", specialContent: .query)
                ]
            )
        }
    }
    
    func getChannelVideosHeaders() -> HeadersList {
        if let headers = self.customHeaders[.channelHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
    
    func getPlaylistVideosHeaders() -> HeadersList {
        if let headers = self.customHeaders[.playlistHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
    
    func getPlaylistVideosContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.playlistContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
    
    func getHomeVideosContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.homeVideosContinuationHeader] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
    
    func searchContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.searchContinuationHeaders] {
            return headers
        } else {
            return getHomeVideosContinuationHeaders()
        }
    }
    
    func channelContinuationHeaders() -> HeadersList {
        if let headers = self.customHeaders[.channelContinuationHeaders] {
            return headers
        } else {
            return HeadersList(
                url: URL(string: "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false")!,
                method: .POST,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Host", content: "www.youtube.com"),
                    .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                    .init(name: "Accept-Language", content: "\(HeadersModel.shared.selectedLocale);q=0.9"),
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
                ]
            )
        }
    }
}
