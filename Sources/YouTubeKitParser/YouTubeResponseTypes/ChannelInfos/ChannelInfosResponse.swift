//
//  ChannelInfosResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 22.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public struct ChannelInfosResponse: YouTubeResponse {
    public static let headersType: HeaderTypes = .channelHeaders
    
    public static let parametersValidationList: ValidationList = [.browseId: .channelIdValidator]
    
    /// Array of thumbnails representing the avatar of the channel (the image in the round on YouTube's website).
    ///
    /// Usually sorted by resolution, from low to high.
    public var avatarThumbnails: [YTThumbnail] = []
    
    /// Array of thumbnails representing the banner of the channel (the long rectangle image on YouTube's website).
    ///
    /// Usually sorted by resolution, from low to high.
    public var bannerThumbnails: [YTThumbnail] = []
    
    /// Array of string identifiers of the badges that a channel has.
    ///
    /// Usually like "BADGE\_STYLE\_TYPE\_VERIFIED"
    public var badges: [String] = []
    
    /// Dictionnary associating a ``ChannelInfosResponse/RequestTypes-swift.enum`` with some content, used to store multiple different ``ChannelContent`` for different types. It can be seen as some cache for every type of ``ChannelInfosResponse/RequestTypes-swift.enum``.
    ///
    /// You can also merge the content that contains by using:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(type: .wantedType, youtubeModel: YTM) { result in
    ///     switch result {
    ///     case .success(let newInstance):
    ///         myInstance.channelContentStore.merge(newInstance.channelContentStore, uniquingKeysWith: { (_, new) in new }) /// Will merge the two instances results and keep the most recent data.
    ///     case .failure(let error):
    ///         // Deal with the error
    ///     }
    /// }
    /// ```
    public var channelContentStore: [RequestTypes : any ChannelContent] = [:]
    
    /// Dictionnary associating a ``ChannelInfosResponse/RequestTypes-swift.enum`` with an optional continuation token, it is nil if the results reached the end of the list, (e.g: all the videos of a channel have been fetched).
    ///
    /// You can use this token like this:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// if let myVideosContinuation = channelContentContinuationStore[.videos] {
    ///     let directsRequestContinuationResult = try await myVideosContinuation.getChannelContentContinuation(myVideosContinuation.Type.self /* precise the proper type */, youtubeModel: YTM)
    /// }
    /// ```
    public var channelContentContinuationStore: [RequestTypes : String?] = [:]
    
    /// Channel's identifier, can be used to get the informations about the channel.
    ///
    /// For example:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let channelId: String = ...
    /// ChannelInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.browseId : channelId], result: { result in
    ///     switch result {
    ///     case .success(let response):
    ///         print(response)
    ///     case .failure(let error):
    ///         // Deal with the error
    ///         print(error)
    ///     }
    /// })
    /// ```
    public var channelId: String?
    
    /// ChannelContent that is displayed, by default if no params were precised is the default content, the requested content in case some params were given.
    public var currentContent: (any ChannelContent)?
    
    /// Dictionnary that lets you create your own ChannelContent processing.
    ///
    /// Example:
    /// Let's imagine that we have a recommended channel category (it exists but is not implemented), the params to send for this category is "EghjaGFubmVscIGBAoCUgA%3D".  We want to create a new ``ChannelContent`` for this.
    /// ```swift
    /// struct RecommendedChannels: ChannelContent {
    ///     /// You can add here the properties that define a RecommendedChannels like an array of Channel.
    ///
    ///     /// Make conform to ChannelContent
    ///     static var type: ChannelInfosResponse.RequestTypes = .custom("RecommendedChannels")
    ///     static func canDecode(json: JSON) -> Bool {
    ///         guard let endpoint: String = json["endpoint", "commandMetadata", "webCommandMetadata", "url"].string else { return false }
    ///         return endpoint.components(separatedBy: "/").last == "channels"
    ///     }
    ///
    ///     static func decodeJSON(json: JSON) -> RecommendedChannels? {} /// Implement with this the function
    /// }
    /// ```
    ///
    /// Then append this type to requestTypes like this:
    /// ```swift
    /// ChannelInfosResponse.requestTypes[.custom("RecommendedChannels")] = RecommendedChannels.self
    /// ```
    ///
    /// And you can now make the request:
    ///
    /// ```swift
    /// let recommendedChannels = await channelInfosResponse.getChannelContent(type: .custom("RecommendedChannels"))
    /// ```
    public static let requestTypes: [RequestTypes : any ChannelContent.Type] = [
        .videos: Videos.self,
        .directs: Directs.self,
        .shorts: Shorts.self,
        .playlists: Playlists.self
    ]
    
    /// Boolean indicating if the subscribe button (on YouTube's website) can be activated or not -> only when cookies are given see ``YouTubeModel/cookies``.
    public var isSubcribeButtonEnabled: Bool?
    
    /// Name of the channel.
    public var name: String?
    
    /// Public handle of the channel, the "@" identifier of the channel.
    public var handle: String?
        
    /// Dictionnary of a string representing the params to send to get the RequestType from YouTube.
    public var requestParams: [RequestTypes : String] = [:]
    
    /// Count of subscriber of the channel.
    @available(*, deprecated, renamed: "subscriberCount")
    public var subscribersCount: String? {
        get {
            return self.subscriberCount
        } set {
            self.subscriberCount = newValue
        }
    }
    
    /// Count of subscriber of the channel.
    public var subscriberCount: String?
    
    /// Boolean indicating if the user from the provided cookies is subscribed to the channel -> only when cookies are given see ``YouTubeModel/cookies``.
    public var subscribeStatus: Bool?
    
    /// Count of videos that the channel posted.
    @available(*, deprecated, renamed: "videoCount")
    public var videosCount: String? {
        get {
            return self.videoCount
        } set {
            self.videoCount = newValue
        }
    }
    
    /// Count of videos that the channel posted.
    public var videoCount: String?
    
    /// A short description of the channel.
    public var shortDescription: String?
    
    /// The keywords of the channel.
    public var keywords: [String]?
            
    public static func decodeJSON(json: JSON) -> ChannelInfosResponse {
        var toReturn = ChannelInfosResponse()
                
        if json["header", "pageHeaderRenderer"].exists() {
            toReturn.extractChannelInfosFromPageHeaderRenderer(json: json)
        } else {
            toReturn.extractChannelInfosFromC4TabbedHeaderRenderer(json: json)
        }
        
        /// Time to get the params to be able to make channel content requests.
        
        guard let tabsArray = json["contents", "twoColumnBrowseResultsRenderer", "tabs"].array else { return toReturn }
        
        var nonCheckedRequestTypes = requestTypes
        
        for tab in tabsArray {
            for (requestType, requestClass) in nonCheckedRequestTypes {
                if requestClass.isTabOfSelfType(json: tab) {
                    /// The request already given one of the ``ChannelContent`` so we decode it.
                    if tab["tabRenderer", "selected"].bool ?? false, requestClass.canDecode(json: tab) {
                        if let channelId = toReturn.channelId {
                            let decodedContent = requestClass.decodeJSONFromTab(
                                tab,
                                channelInfos: .init(
                                    channelId: channelId,
                                    name: toReturn.name
                                )
                            )
                            toReturn.channelContentStore[requestType] = decodedContent
                            toReturn.channelContentContinuationStore[requestType] = requestClass.getContinuationFromTab(json: tab)
                            toReturn.currentContent = decodedContent
                        }
                    }
                    /// We now get the params for the type.
                    guard let params = getParams(json: tab) else { continue }
                    
                    toReturn.requestParams[requestType] = params
                    
                    nonCheckedRequestTypes.removeValue(forKey: requestType)
                }
            }
        }
                
        return toReturn
    }
    
    // TODO: remove that possibility in the future if it's definitely not used anymore
    private mutating func extractChannelInfosFromC4TabbedHeaderRenderer(json: JSON) {
        let channelInfos = json["header", "c4TabbedHeaderRenderer"]
        
        
        self.channelId = channelInfos["channelId"].string
        
        /// Create a new json to replace the "avatar" dictionnary key to the "thumbnail" for the extraction with ``YTThumbnail/appendThumbnails(json:thumbnailList:)`` to work.
        YTThumbnail.appendThumbnails(json: channelInfos["avatar"], thumbnailList: &self.avatarThumbnails)
        
        YTThumbnail.appendThumbnails(json: channelInfos["banner"], thumbnailList: &self.bannerThumbnails)
        
        if let badgesList = channelInfos["badges"].array {
            for badge in badgesList {
                if let badgeName = badge["metadataBadgeRenderer", "style"].string {
                    self.badges.append(badgeName)
                }
            }
        }
        
        self.isSubcribeButtonEnabled = channelInfos["subscribeButton", "subscribeButtonRenderer", "enabled"].bool
        
        self.name = channelInfos["title"].string
        if let handle = channelInfos["channelHandleText", "runs"].array?.first?["text"].string, !handle.isEmpty {
            self.handle = handle
        } else {
            self.handle = channelInfos["navigationEndpoint", "browseEndpoint", "canonicalBaseUrl"].string?.replacingOccurrences(of: "/", with: "") // Need to remove the first slash because the string is like "/@ChannelHandle"
        }
        
        self.subscribeStatus = channelInfos["subscribeButton", "subscribeButtonRenderer", "subscribed"].bool
        
        self.subscriberCount = channelInfos["subscriberCountText", "simpleText"].string
        
        self.videoCount = channelInfos["videosCountText", "runs"].arrayValue.map({$0["text"].stringValue}).joined()
    }
    
    private mutating func extractChannelInfosFromPageHeaderRenderer(json: JSON) {
        let channelInfos = json["header", "pageHeaderRenderer", "content", "pageHeaderViewModel"]
        let metadata = json["metadata", "channelMetadataRenderer"]
        
        let subscribeButton: JSON? = channelInfos["actions", "flexibleActionsViewModel", "actionsRows"].arrayValue.reduce([] as [JSON], {var mutArray = $0; mutArray.append(contentsOf: $1["actions"].arrayValue); return mutArray}).first(where: {$0["subscribeButtonViewModel"].exists()})?["subscribeButtonViewModel"]
        
        self.channelId = metadata["externalId"].string ?? subscribeButton?["channelId"].string
        
        /// Create a new json to replace the "avatar" dictionnary key to the "thumbnail" for the extraction with ``YTThumbnail/appendThumbnails(json:thumbnailList:)`` to work.
        YTThumbnail.appendThumbnails(json: channelInfos["image", "decoratedAvatarViewModel", "avatar", "avatarViewModel"], thumbnailList: &self.avatarThumbnails)
        
        YTThumbnail.appendThumbnails(json: channelInfos["banner", "imageBannerViewModel"], thumbnailList: &self.bannerThumbnails)
        
        /* badges are disabled for the moment
        if let badgesList = channelInfos["badges"].array {
            for badge in badgesList {
                if let badgeName = badge["metadataBadgeRenderer", "style"].string {
                    self.badges.append(badgeName)
                }
            }
        }
         */
        
        self.isSubcribeButtonEnabled = !(subscribeButton?["disableSubscribeButton"].bool ?? true) // TODO: add notificationBell
        
        self.name = channelInfos["title", "dynamicTextViewModel", "text", "content"].string ?? metadata["title"].string
        
        let metadataRows = channelInfos["metadata", "contentMetadataViewModel", "metadataRows"]
        
        /*
         metadata -> contentMetadataViewModel -> [metadataRows] -> [metadataParts] -> text -> content
         */
        self.handle = metadataRows.arrayValue
            .first(where: {$0["metadataParts"].arrayValue.contains(where: {$0["text", "content"].stringValue.starts(with: "@")})})?["metadataParts"].arrayValue // selects the metadataParts
            .first(where: {$0["text", "content"].stringValue.starts(with: "@")})?["text", "content"].string
                
        //self.subscribeStatus = channelInfos["subscribeButton", "subscribeButtonRenderer", "subscribed"].bool TODO: broken at the moment
        
        // TODO: implement badges extraction via dynamicTextViewModel -> text -> attachmentRuns
        
        self.subscriberCount = !metadataRows.arrayValue.isEmpty ? metadataRows.arrayValue.last!["metadataParts", 0, "text", "content"].string : nil
        
        self.videoCount = !metadataRows.arrayValue.isEmpty ? metadataRows.arrayValue.last!["metadataParts"].arrayValue.count > 1 ? metadataRows.arrayValue.last!["metadataParts"].arrayValue[1]["text", "content"].string : nil : nil
        
        self.shortDescription = metadata["description"].string
        
        self.keywords = metadata["keywords"].string?.components(separatedBy: " ")
    }
    
    /// Types of request you can do to retrieve some of the channel's content, channel's tabs on YouTube's website.
    public enum RequestTypes: Hashable, Equatable, Sendable {
        case directs
        case playlists
        case shorts
        case videos
        /// See the documentation of ``ChannelInfosResponse/requestTypes-swift.type.property`` to make a custom ``ChannelContent`` handling.
        case custom(String)
    }
    
    /// Get a content from a channel, the content represents one of the tabs you see when browsing on YouTube's website in a channel's webpage. For example: Home, Videos, Shorts, Playlists etc...
    /// - Parameters:
    ///   - type: Type of content requested, (the tab of the wanted content).
    ///   - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - result: An instance of ``ChannelInfosResponse`` containing the result and updated channel properties or/and an error.
    ///
    /// You can update your instance of ``ChannelInfosResponse``with the new one by using ``ChannelInfosResponse/copyProperties(of:)`` with the new instance ``ChannelInfosResponse`` that this method returns.
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(forType: .wantedType, youtubeModel: YTM) { newInstance in
    ///     switch result {
    ///     case .success(let newInstance):
    ///         myInstance.copyProperties(of: newInstance) /// Will update to the properties of the newInstance
    ///     case .failure(let error):
    ///         // Deal with the error
    ///     }
    /// }
    /// ```
    ///
    /// You can also merge the ``ChannelInfosResponse/channelContentStore`` that contains all the fetched tab data, by using:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(forType: .wantedType, youtubeModel: YTM) { result in
    ///     switch result {
    ///     case .success(let newInstance):
    ///         myInstance.channelContentStore.merge(newInstance.channelContentStore, uniquingKeysWith: { (_, new) in new }) /// Will merge the two instances results and keep the most recent data.
    ///     case .failure(let error):
    ///         // Deal with the error
    ///     }
    /// }
    /// ```
    public func getChannelContent(forType type: RequestTypes, youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<ChannelInfosResponse, Error>) -> ()) {
        guard
            let params = requestParams[type]
        else { result(.failure("Something between returnType or params haven't been added where it should, returnType in ChannelInfosResponse.requestTypes and params in ChannelInfosResponse.requestParams")); return }
        guard let channelId = self.channelId else { result(.failure("Channel ID is nil")); return}
        
        ChannelInfosResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.browseId: channelId, .params: params], useCookies: useCookies, result: { channelResponse in
            result(channelResponse)
        })
    }
    
    /// Get a content from a channel, the content represents one of the tabs you see when browsing on YouTube's website in a channel's webpage. For example: Home, Videos, Shorts, Playlists etc...
    /// - Parameters:
    ///   - type: Type of content requested, (the tab of the wanted content).
    ///   - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    /// - Returns: An instance of ``ChannelInfosResponse`` containing the result and updated channel properties or/and an error.
    ///
    /// You can update your instance of ``ChannelInfosResponse``with the new one by using ``ChannelInfosResponse/copyProperties(of:)`` with the new instance ``ChannelInfosResponse`` that this method returns.
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(forType: .wantedType, youtubeModel: YTM) { result in
    ///     switch result {
    ///     case .success(let response):
    ///         myInstance.copyProperties(of: newInstance) /// Will update to the properties of the newInstance
    ///     case .failure(let error):
    ///         // Deal with the error
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// You can also merge the ``ChannelInfosResponse/channelContentStore`` that contains all the fetched tab data, by using:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(forType: .wantedType, youtubeModel: YTM) { result in
    ///     switch result {
    ///     case .success(let response):
    ///          myInstance.channelContentStore.merge(newInstance.channelContentStore, uniquingKeysWith: { (_, new) in new }) /// Will merge the two instances results and keep the most recent data.
    ///     case .failure(let error):
    ///         // Deal with the error
    ///         print(error)
    ///     }
    /// }
    /// ```
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func getChannelContentThrowing(forType type: RequestTypes, youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> ChannelInfosResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<ChannelInfosResponse, Error>) in
            self.getChannelContent(forType: type, youtubeModel: youtubeModel, useCookies: useCookies, result: { channelContent in
                continuation.resume(with: channelContent)
            })
        })
    }
    
    /// Get the continuation results for a certain ChannelContent.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - result: a ``ChannelInfosResponse/ContentContinuation`` representing the result (see definition) or/and an Error indicating why it failed.
    ///
    /// - Note: (For ``ListableChannelContent`` continuations) The elements from the continuation's contents usually don't contain the channel's information. You can still add them by calling ``ListableChannelContent/addChannelInfos(_:)`` or ``mergeListableChannelContentContinuation(_:)`` on the continuation with the information of the channel.
    public func getChannelContentContinuation<T: ChannelContent>(
        _: T.Type,
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil,
        result: @escaping @Sendable (Result<ContentContinuation<T>, Error>) -> Void) {
        guard
            /// Get requestType from the given ChannelContent (T)
            let requestType = channelContentStore.first(where: { element in
                type(of: element.value) == T.self
            })?.key,
            /// Get the continuation token from this requestType
            let continuationToken = channelContentContinuationStore.first(where: {$0.key == requestType})?.value
            else { result(.failure("There is no continuation token for this type (\(T.self)")); return }
        ContentContinuation.sendNonThrowingRequest(
            youtubeModel: youtubeModel,
            data: [.continuation: continuationToken], 
            useCookies: useCookies,
            result: result
        )
    }
    
    /// Get the continuation results for a certain ChannelContent.
    /// - Parameters:
    ///    - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    ///    - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: a ``ChannelInfosResponse/ContentContinuation`` representing the result (see definition) or/and an Error indicating why it failed.
    ///
    /// - Note: (For ``ListableChannelContent`` continuations) The elements from the continuation's contents usually don't contain the channel's information. You can still add them by calling ``ListableChannelContent/addChannelInfos(_:)`` or ``mergeListableChannelContentContinuation(_:)`` on the continuation with the information of the channel.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func getChannelContentContinuationThrowing<T: ChannelContent>(
        _: T.Type,
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil
    ) async throws -> ContentContinuation<T> {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<ContentContinuation<T>, Error>) in
            self.getChannelContentContinuation(T.self, youtubeModel: youtubeModel, useCookies: useCookies, result: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    
    // Deprecated methods
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use getChannelContent(type: RequestTypes, youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<ChannelInfosResponse, Error>) -> ()) instead.") // safer and better to use the result API instead of a tuple
    /// Get a content from a channel, the content represents one of the tabs you see when browsing on YouTube's website in a channel's webpage. For example: Home, Videos, Shorts, Playlists etc...
    /// - Parameters:
    ///   - type: Type of content requested, (the tab of the wanted content).
    ///   - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - result: An instance of ``ChannelInfosResponse`` containing the result and updated channel properties or/and an error.
    ///
    /// You can update your instance of ``ChannelInfosResponse``with the new one by using ``ChannelInfosResponse/copyProperties(of:)`` with the new instance ``ChannelInfosResponse`` that this method returns.
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(type: .wantedType, youtubeModel: YTM) { newInstance, error in
    ///     if let newInstance = newInstance {
    ///         myInstance.copyProperties(of: newInstance) /// Will update to the properties of the newInstance
    ///     }
    /// }
    /// ```
    ///
    /// You can also merge the ``ChannelInfosResponse/channelContentStore`` that contains all the fetched tab data, by using:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(type: .wantedType, youtubeModel: YTM) { newInstance, error in
    ///     if let newInstance = newInstance {
    ///         myInstance.channelContentStore.merge(newInstance.channelContentStore, uniquingKeysWith: { (_, new) in new }) /// Will merge the two instances results and keep the most recent data.
    ///     }
    /// }
    /// ```
    public func getChannelContent(type: RequestTypes, youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (ChannelInfosResponse?, Error?) -> ()) {
        self.getChannelContent(forType: type, youtubeModel: youtubeModel, useCookies: useCookies, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use getChannelContent(type: RequestTypes, youtubeModel: YouTubeModel) async throws -> ChannelInfosResponse instead.") // safer and better to use the throws API instead of a tuple
    /// Get a content from a channel, the content represents one of the tabs you see when browsing on YouTube's website in a channel's webpage. For example: Home, Videos, Shorts, Playlists etc...
    /// - Parameters:
    ///   - type: Type of content requested, (the tab of the wanted content).
    ///   - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    /// - Returns: An instance of ``ChannelInfosResponse`` containing the result and updated channel properties or/and an error.
    ///
    /// You can update your instance of ``ChannelInfosResponse``with the new one by using ``ChannelInfosResponse/copyProperties(of:)`` with the new instance ``ChannelInfosResponse`` that this method returns.
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(type: .wantedType, youtubeModel: YTM) { newInstance, error in
    ///     if let newInstance = newInstance {
    ///         myInstance.copyProperties(of: newInstance) /// Will update to the properties of the newInstance
    ///     }
    /// }
    /// ```
    ///
    /// You can also merge the ``ChannelInfosResponse/channelContentStore`` that contains all the fetched tab data, by using:
    /// ```swift
    /// let YTM = YouTubeModel()
    /// let myInstance: ChannelInfosResponse = ...
    /// myInstance.getChannelContent(type: .wantedType, youtubeModel: YTM) { newInstance, error in
    ///     if let newInstance = newInstance {
    ///         myInstance.channelContentStore.merge(newInstance.channelContentStore, uniquingKeysWith: { (_, new) in new }) /// Will merge the two instances results and keep the most recent data.
    ///     }
    /// }
    /// ```
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func getChannelContent(type: RequestTypes, youtubeModel: YouTubeModel) async -> (ChannelInfosResponse?, Error?) {
        do {
            let result = try await self.getChannelContentThrowing(forType: type, youtubeModel: youtubeModel)
            return (result, nil)
        } catch {
            return (nil, error)
        }
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use getChannelContentContinuation<T: ChannelContent>(_: T.Type, youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping (Result<ContentContinuation<T>, Error>) -> Void) instead.") // safer and better to use the throws API instead of a tuple
    /// Get the continuation results for a certain ChannelContent.
    /// - Parameters:
    ///   - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    ///   - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    ///   - result: a ``ChannelInfosResponse/ContentContinuation`` representing the result (see definition) or/and an Error indicating why it failed.
    public func getChannelContentContinuation<T: ChannelContent>(
        _: T.Type,
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil,
        result: @escaping @Sendable (ContentContinuation<T>?, Error?
        ) -> ()) {
        self.getChannelContentContinuation(T.self, youtubeModel: youtubeModel, useCookies: useCookies, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use public func getChannelContentContinuation<T: ChannelContent>(_: T.Type, youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> ContentContinuation<T> instead.") // safer and better to use the throws API instead of a tuple
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get the continuation results for a certain ChannelContent.
    /// - Parameters:
    ///    - youtubeModel: the ``YouTubeModel`` that will be used to get the request headers.
    ///    - useCookies: boolean that precises if the request should include the model's ``YouTubeModel/cookies``, if set to nil, the value will be taken from ``YouTubeModel/alwaysUseCookies``. The cookies will be added to the `Cookie` HTTP header if one is already present or a new one will be created if not.
    /// - Returns: a ``ChannelInfosResponse/ContentContinuation`` representing the result (see definition) or/and an Error indicating why it failed.
    public func getChannelContentContinuation<T: ChannelContent>(
        _: T.Type,
        youtubeModel: YouTubeModel,
        useCookies: Bool? = nil
    ) async -> (ContentContinuation<T>?, Error?) {
        do {
            let result = try await self.getChannelContentContinuationThrowing(T.self, youtubeModel: youtubeModel, useCookies: useCookies)
            return (result, nil)
        } catch {
            return (nil, error)
        }
    }
    
    
    // ContentContinuation
    
    /// Struct representing the continuation of a certain ``ChannelContent``.
    public struct ContentContinuation<T: ChannelContent>: YouTubeResponse {
        public static var headersType: HeaderTypes {
            return .channelContinuationHeaders
        }
        
        public static var parametersValidationList: ValidationList {
            return [.continuation: .existenceValidator]
        }
        
        /// Content of the continuation.
        public var contents: T?
    
        /// Token that you will be able to use to continue the continuation, nil if there isn't
        public var newContinuationToken: String?
        
        public static func decodeJSON(json: JSON) -> ContentContinuation {
            return T.decodeContinuation(json: json)
        }
    }
        
    /// Struct representing the "Videos" tab in a channel's webpage on YouTube's website.
    public struct Videos: ListableChannelContent {
        public static let type: ChannelInfosResponse.RequestTypes = .videos
            
        public static let itemsTypes: [any YTSearchResult.Type] = [YTVideo.self]
        
        public var items: [any YTSearchResult] = []
                
        public static func canDecode(json: JSON) -> Bool {
            return isTabOfSelfType(json: json)
        }
        
        public static func decodeJSONFromTab(_ tab: JSON, channelInfos: YTLittleChannelInfos?) -> Videos? {
            guard let videosArray = tab["tabRenderer", "content", "richGridRenderer", "contents"].array else { return nil }
            var toReturn = Videos()
            for video in videosArray {
                let videoJSON = video["richItemRenderer", "content", "videoRenderer"]
                if var decodedVideo = YTVideo.decodeJSON(json: videoJSON) {
                    if let channelInfos = channelInfos {
                        decodedVideo.channel = channelInfos
                    }
                    toReturn.items.append(decodedVideo)
                }
            }
            return toReturn
        }
        
        public static func decodeContinuation(json: JSON) -> ContentContinuation<Videos> {
            var toReturn = ContentContinuation<Videos>()
            guard
                let itemsArray = json["onResponseReceivedActions"].array,
                    itemsArray.count > 0,
                    let itemsArray = itemsArray[0]["appendContinuationItemsAction", "continuationItems"].array
            else { return toReturn }
            
            var result = Videos()
            
            for continuationItem in itemsArray {
                let videoJSON = continuationItem["richItemRenderer", "content", "videoRenderer"]
                if let decodedVideo = YTVideo.decodeJSON(json: videoJSON) {
                    result.items.append(decodedVideo)
                } else if let continuationToken = continuationItem["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                    toReturn.newContinuationToken = continuationToken
                }
            }
            
            toReturn.contents = result
            
            return toReturn
        }
        
        public static func isTabOfSelfType(json: JSON) -> Bool {
            guard let tabURL = json["tabRenderer", "endpoint", "commandMetadata", "webCommandMetadata", "url"].string else { return false }
            return tabURL.ytkFirstGroupMatch(for: "[\\S]*\\/([\\S]*)") == "videos" // last component of the path
        }
    }
    
    /// Struct representing the "Shorts" tab in a channel's webpage on YouTube's website.
    public struct Shorts: ListableChannelContent {
        public static let type: ChannelInfosResponse.RequestTypes = .shorts
        
        public static let itemsTypes: [any YTSearchResult.Type] = [YTVideo.self]

        public var items: [any YTSearchResult] = []
                
        public static func canDecode(json: JSON) -> Bool {
            return isTabOfSelfType(json: json)
        }
        
        public static func decodeContinuation(json: JSON) -> ContentContinuation<Shorts> {
            var toReturn = ContentContinuation<Shorts>()
            guard
                let itemsArray = json["onResponseReceivedActions"].array,
                    itemsArray.count > 0,
                    let itemsArray = itemsArray[0]["appendContinuationItemsAction", "continuationItems"].array
            else { return toReturn }
            
            var result = Shorts()
            
            for continuationItem in itemsArray {
                let shortJSON = continuationItem["richItemRenderer", "content"]
                if let decodedShort = YTVideo.decodeShortFromJSON(json: shortJSON["reelItemRenderer"]) ?? YTVideo.decodeShortFromLockupJSON(json: shortJSON["shortsLockupViewModel"]) {
                    result.items.append(decodedShort)
                } else if let continuationToken = continuationItem["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                    toReturn.newContinuationToken = continuationToken
                }
            }
            
            toReturn.contents = result
            
            return toReturn
        }
        
        public static func decodeJSONFromTab(_ tab: JSON, channelInfos: YTLittleChannelInfos?) -> Shorts? {
            guard let videosArray = tab["tabRenderer", "content", "richGridRenderer", "contents"].array else { return nil }
            var toReturn = Shorts()
            for video in videosArray {
                if var decodedVideo = YTVideo.decodeShortFromJSON(json: video["richItemRenderer", "content", "reelItemRenderer"]) ?? YTVideo.decodeShortFromLockupJSON(json: video["richItemRenderer", "content", "shortsLockupViewModel"]) {
                    if let channelInfos = channelInfos {
                        decodedVideo.channel = channelInfos
                    }
                    toReturn.items.append(decodedVideo)
                }
            }
            return toReturn
        }
        
        public static func isTabOfSelfType(json: JSON) -> Bool {
            guard let tabURL = json["tabRenderer", "endpoint", "commandMetadata", "webCommandMetadata", "url"].string else { return false }
            return tabURL.ytkFirstGroupMatch(for: "[\\S]*\\/([\\S]*)") == "shorts" // last component of the path
        }
    }
    
    /// Struct representing the "Directs" tab in a channel's webpage on YouTube's website.
    public struct Directs: ListableChannelContent {
        public static let type: ChannelInfosResponse.RequestTypes = .directs
        
        public static let itemsTypes: [any YTSearchResult.Type] = [YTVideo.self]

        public var items: [any YTSearchResult] = []
                
        public static func canDecode(json: JSON) -> Bool {
            return isTabOfSelfType(json: json)
        }
        
        public static func decodeContinuation(json: JSON) -> ContentContinuation<Directs> {
            var toReturn = ContentContinuation<Directs>()
            guard
                let itemsArray = json["onResponseReceivedActions"].array,
                    itemsArray.count > 0,
                    let itemsArray = itemsArray[0]["appendContinuationItemsAction", "continuationItems"].array
            else { return toReturn }
            
            var result = Directs()
            
            for continuationItem in itemsArray {
                let videoJSON = continuationItem["richItemRenderer", "content", "videoRenderer"]
                if let decodedVideo = YTVideo.decodeJSON(json: videoJSON) {
                    result.items.append(decodedVideo)
                } else if let continuationToken = continuationItem["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                    toReturn.newContinuationToken = continuationToken
                }
            }
            
            toReturn.contents = result
            
            return toReturn
        }
        
        public static func decodeJSONFromTab(_ tab: JSON, channelInfos: YTLittleChannelInfos?) -> Directs? {
            guard let videosArray = tab["tabRenderer", "content", "richGridRenderer", "contents"].array else { return nil }
            var toReturn = Directs()
            for video in videosArray {
                let videoJSON = video["richItemRenderer", "content", "videoRenderer"]
                if YTVideo.canBeDecoded(json: videoJSON), var decodedVideo = YTVideo.decodeJSON(json: videoJSON) {
                    if let channelInfos = channelInfos {
                        decodedVideo.channel = channelInfos
                    }
                    toReturn.items.append(decodedVideo)
                }
            }
            return toReturn
        }
        
        public static func isTabOfSelfType(json: JSON) -> Bool {
            guard let tabURL = json["tabRenderer", "endpoint", "commandMetadata", "webCommandMetadata", "url"].string else { return false }
            return tabURL.ytkFirstGroupMatch(for: "[\\S]*\\/([\\S]*)") == "streams" // last component of the path
        }
    }
    
    /// Struct representing the "Playlists" tab in a channel's webpage on YouTube's website.
    public struct Playlists: ListableChannelContent {
        public static let type: ChannelInfosResponse.RequestTypes = .playlists
        
        public static let itemsTypes: [any YTSearchResult.Type] = [YTPlaylist.self]

        public var items: [any YTSearchResult] = []
                
        public static func canDecode(json: JSON) -> Bool {
            return isTabOfSelfType(json: json)
        }
        
        public static func decodeContinuation(json: JSON) -> ContentContinuation<Playlists> {
            var toReturn = ContentContinuation<Playlists>()
            guard
                let itemsArray = json["onResponseReceivedActions"].array,
                    itemsArray.count > 0,
                    let itemsArray = itemsArray[0]["appendContinuationItemsAction", "continuationItems"].array
            else { return toReturn }
            
            var result = Playlists()
            
            for continuationItem in itemsArray {
                if YTPlaylist.canShowBeDecoded(json: continuationItem["gridShowRenderer"]), let decodedShow = YTPlaylist.decodeShowFromJSON(json: continuationItem["gridShowRenderer"]) {
                    result.items.append(decodedShow)
                } else if let decodedPlaylist = YTPlaylist.decodeJSON(json: continuationItem["gridPlaylistRenderer"]) {
                    /// Decoding normal playlist
                    result.items.append(decodedPlaylist)
                } else if let continuationToken = continuationItem["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                    toReturn.newContinuationToken = continuationToken
                }
            }
            
            toReturn.contents = result
            
            return toReturn
        }
        
        public static func decodeJSONFromTab(_ tab: JSON, channelInfos: YTLittleChannelInfos?) -> Playlists? {
            guard let playlistGroupsArray = tab["tabRenderer", "content", "sectionListRenderer", "contents"].array else { return nil }
            var toReturn = Playlists()
            for playlistGroup in playlistGroupsArray {
                guard let secondPlaylistGroupArray = playlistGroup["itemSectionRenderer", "contents"].array else { continue }
                for secondPlaylistGroup in secondPlaylistGroupArray {
                    guard let playlistArray = secondPlaylistGroup["gridRenderer", "items"].array else { continue }
                    for playlist in playlistArray {
                        if var decodedPlaylist = YTPlaylist.decodeJSON(json: playlist["gridPlaylistRenderer"]) ?? YTPlaylist.decodeLockupJSON(json: playlist["lockupViewModel"]) {
                            if let channelInfos = channelInfos {
                                decodedPlaylist.channel = channelInfos
                            }
                            toReturn.items.append(decodedPlaylist)
                        }
                    }
                }
            }
            return toReturn
        }
        
        public static func getContinuationFromTab(json: JSON) -> String? {
            guard let playlistGroupsArray = json["tabRenderer", "content", "sectionListRenderer", "contents"].array else { return nil }
            for playlistGroup in playlistGroupsArray {
                guard let secondPlaylistGroupArray = playlistGroup["itemSectionRenderer", "contents"].array else { continue }
                for secondPlaylistGroup in secondPlaylistGroupArray {
                    guard let playlistArray = secondPlaylistGroup["gridRenderer", "items"].array else { continue }
                    for potentialContinuation in playlistArray.reversed() {
                        if let token = potentialContinuation["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                            return token
                        }
                    }
                }
            }
            return nil
        }
        
        public static func isTabOfSelfType(json: JSON) -> Bool {
            guard let tabURL = json["tabRenderer", "endpoint", "commandMetadata", "webCommandMetadata", "url"].string else { return false }
            return tabURL.ytkFirstGroupMatch(for: "[\\S]*\\/([\\S]*)") == "playlists" // last component of the path
        }
    }
    
    /// Copy properties from another ``ChannelInfosResponse`` to the current ``ChannelInfosResponse`` instance.
    /// - Parameter otherResponse: the ``ChannelInfosResponse`` where the infos will be taken of.
    public mutating func copyProperties(of channel: YTChannel) {
        self.avatarThumbnails = channel.thumbnails
        self.name = channel.name
        self.handle = channel.handle
        self.videoCount = channel.videoCount
        self.subscriberCount = channel.subscriberCount
    }
    
    /// Copy properties from another ``ChannelInfosResponse`` to the current ``ChannelInfosResponse`` instance.
    /// - Parameter otherResponse: the ``ChannelInfosResponse`` where the infos will be taken of.
    public mutating func copyProperties(of otherResponse: ChannelInfosResponse) {
        self.avatarThumbnails = otherResponse.avatarThumbnails
        self.bannerThumbnails = otherResponse.bannerThumbnails
        self.currentContent = otherResponse.currentContent
        self.isSubcribeButtonEnabled = otherResponse.isSubcribeButtonEnabled
        self.name = otherResponse.name
        self.handle = otherResponse.handle
        self.subscribeStatus = otherResponse.subscribeStatus
        self.subscriberCount = otherResponse.subscriberCount
        self.videoCount = otherResponse.videoCount
    }
    
    /// Put the `channelContent` into ``ChannelInfosResponse/channelContentStore`` with `category` as key.
    /// - Parameters:
    ///   - channelContent: The ``ChannelContent`` to be added.
    ///   - category: The ``RequestTypes`` where `channelContent` will be stored.
    public mutating func mergeChannelContent(_ channelContent: any ChannelContent, to category: RequestTypes) {
        self.channelContentStore[category] = channelContent
    }
    
    /// Merge a ``ListableChannelContent``'s continuation to this instance of ``ChannelInfosResponse``.
    /// - Parameter continuation: the continuation to be merged.
    public mutating func mergeListableChannelContentContinuation<T>(_ continuation: ContentContinuation<T>) where T: ListableChannelContent {
        self.channelContentContinuationStore[T.type] = continuation.newContinuationToken
        guard var newChannelContent = self.channelContentStore[T.type] as? (any ListableChannelContent) else { return }
        
        var mutableContinuation = continuation
        if let channelId = self.channelId {
            mutableContinuation.contents?.addChannelInfos(.init(channelId: channelId, name: self.name, thumbnails: self.avatarThumbnails))
        }
        
        newChannelContent.items.append(contentsOf: mutableContinuation.contents?.items ?? [])
        self.channelContentStore[T.type] = newChannelContent
    }
    
    /// Method that can be used to retrieve some request's params to make a request to get an instance of this ``ChannelContent`` type.
    /// - Parameter json: the JSON to be decoded.
    /// - Returns: The params that would be used to make the request, in a custom ``ChannelContent``conforming struct you would typically put its custom ``ChannelInfosResponse/RequestTypes-swift.enum`` associated with the params in ``ChannelInfosResponse/requestParams``.
    public static func getParams(json: JSON) -> String? {
        return json["tabRenderer", "endpoint", "browseEndpoint", "params"].string
    }
    
    /// Method that can be used to retrieve some request's params to make a request to get an instance of this ``ChannelContent`` type.
    /// - Parameter data: the Data to be decoded.
    /// - Returns: The params that would be used to make the request, in a custom ``ChannelContent``conforming struct you would typically put its custom ``ChannelInfosResponse/RequestTypes-swift.enum`` associated with the params in ``ChannelInfosResponse/requestParams``.
    public static func getParams(data: Data) -> String? {
        return getParams(json: JSON(data))
    }
}
