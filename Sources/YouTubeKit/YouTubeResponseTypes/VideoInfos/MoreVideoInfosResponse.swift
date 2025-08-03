//
//  MoreVideoInfosResponse.swift
//
//
//  Created by Antoine Bollengier on 16.10.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//

import Foundation

public struct MoreVideoInfosResponse: YouTubeResponse {
    public static let headersType: HeaderTypes = .moreVideoInfosHeaders
    
    public static let parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    /// Title of the video.
    public var videoTitle: String?
    
    /// Two strings representing the views count.
    ///
    /// e.g: `shortViewsCount` could be "334 k views" and `fullViewsCount` could be "334 977 views".
    public var viewsCount: (shortViewsCount: String?, fullViewsCount: String?)
    
    /// Two string representing the time the video was posted.
    ///
    /// e.g: `postedDate` could be "1 oct. 2023" and `relativePostedDate` could be "2 weeks ago".
    public var timePosted: (postedDate: String?, relativePostedDate: String?)
    
    /// Channel that posted the video.
    public var channel: YTChannel?
    
    /// Description of the video.
    ///
    /// To get the full text description you can do
    /// ```swift
    /// let myVideoResponse: MoreVideoInfosResponse
    /// if let splittedVideoDescription = myVideoResponse.videoDescription {
    ///     let myFullDescription = splittedVideoDescription.map({$0.text ?? ""}).joined()
    /// }
    /// ```
    public var videoDescription: [YouTubeDescriptionPart]?
    
    /// Comment that YouTube chooses and that is supposed to introduce the comments section.
    ///
    /// On YouTube's desktop version it is the comment right after the channel at the bottom of the player.
    /// The `avatar` represents the avatar of the user who published the comment and `teaserText` is a part of this comment (can be the entire comment if it is short enough).
    public var teaserComment: (avatar: [YTThumbnail]?, teaserText: String?)
    
    /// Token that can be used to fetch the comments section.
    public var commentsContinuationToken: String?
    
    /// String representing the count of comments on the video.
    public var commentsCount: String?
    
    /// Videos recommended by YouTube that go along the one that is currently playing.
    ///
    /// On YouTube's desktop version they are the videos on the right.
    public var recommendedVideos: [any YTSearchResult] = []
    
    /// Continuation token that can be used to fetch more recommended videos.
    public var recommendedVideosContinuationToken: String?
    
    /// Chapters of the video.
    public var chapters: [Chapter]?
    
    /// String representing the count of likes the video has.
    ///
    /// `defaultState` represents the count of like without the user's like (if he did like) and `clickedState` represents the new count of likes after the user clicked on the like button.
    public var likesCount: (defaultState: String?, clickedState: String?)
    
    /// Data that is normally present if authentication cookies when the request was made.
    public var authenticatedInfos: AuthenticatedData?
    
    public init(videoTitle: String? = nil,
                viewsCount: (shortViewsCount: String?, fullViewsCount: String?) = (nil, nil),
                timePosted: (postedDate: String?, relativePostedDate: String?) = (nil, nil),
                channel: YTChannel? = nil,
                videoDescription: [YouTubeDescriptionPart]? = nil,
                teaserComment: (avatar: [YTThumbnail]?, teaserText: String?) = (nil, nil),
                commentsContinuationToken: String? = nil,
                commentsCount: String? = nil,
                recommendedVideos: [any YTSearchResult] = [],
                recommendedVideosContinuationToken: String? = nil,
                chapters: [Chapter]? = nil,
                likesCount: (defaultState: String?, clickedState: String?) = (nil, nil),
                authenticatedInfos: AuthenticatedData? = nil) {
        
        self.videoTitle = videoTitle
        self.viewsCount = viewsCount
        self.timePosted = timePosted
        self.channel = channel
        self.videoDescription = videoDescription
        self.teaserComment = teaserComment
        self.commentsContinuationToken = commentsContinuationToken
        self.commentsCount = commentsCount
        self.recommendedVideos = recommendedVideos
        self.recommendedVideosContinuationToken = recommendedVideosContinuationToken
        self.chapters = chapters
        self.likesCount = likesCount
        self.authenticatedInfos = authenticatedInfos
    }
    
    public static func decodeJSON(json: JSON) -> MoreVideoInfosResponse {
        var toReturn = MoreVideoInfosResponse()
        
        var isAccountConnected: Bool = false
        if !(json["responseContext", "mainAppWebResponseContext", "loggedOut"].bool ?? true) {
            // Response was made with authentication cookies
            isAccountConnected = true
            toReturn.authenticatedInfos = AuthenticatedData(likeStatus: nil as YTLikeStatus?)
        }
        
        for contentPart in json["contents", "twoColumnWatchNextResults", "results", "results", "contents"].arrayValue {
            if contentPart["videoPrimaryInfoRenderer"].exists() {
                let videoPrimaryInfos = contentPart["videoPrimaryInfoRenderer"]
                toReturn.videoTitle = videoPrimaryInfos["title", "runs"].arrayValue.map({$0["text"].stringValue}).joined()
                toReturn.viewsCount.fullViewsCount = videoPrimaryInfos["viewCount", "videoViewCountRenderer", "viewCount", "simpleText"].string
                toReturn.viewsCount.shortViewsCount = videoPrimaryInfos["viewCount", "videoViewCountRenderer", "extraShortViewCount", "simpleText"].string ?? videoPrimaryInfos["viewCount", "videoViewCountRenderer", "shortViewCount", "simpleText"].string
                toReturn.timePosted.postedDate = videoPrimaryInfos["dateText", "simpleText"].string
                toReturn.timePosted.relativePostedDate = videoPrimaryInfos["relativeDateText", "simpleText"].string
                for button in videoPrimaryInfos["videoActions", "menuRenderer", "topLevelButtons"].arrayValue {
                    if button["segmentedLikeDislikeButtonRenderer"].exists() {
                        let likeButton = button["segmentedLikeDislikeButtonRenderer", "likeButton", "toggleButtonRenderer"]
                        let dislikeButton = button["segmentedLikeDislikeButtonRenderer", "dislikeButton", "toggleButtonRenderer"]
                        if isAccountConnected {
                            if likeButton["isToggled"].boolValue {
                                toReturn.authenticatedInfos?.likeStatus = .liked
                            } else if dislikeButton["isToggled"].boolValue {
                                toReturn.authenticatedInfos?.likeStatus = .disliked
                            } else {
                                toReturn.authenticatedInfos?.likeStatus = .nothing
                            }
                        }
                        toReturn.likesCount.defaultState = button["segmentedLikeDislikeButtonRenderer", "likeCount"].string
                        if toReturn.likesCount.defaultState == nil {
                            toReturn.likesCount.defaultState = button["segmentedLikeDislikeButtonRenderer", "likeButton", "toggleButtonRenderer", "defaultText", "simpleText"].string
                        }
                        toReturn.likesCount.clickedState = button["segmentedLikeDislikeButtonRenderer", "likeButton", "toggleButtonRenderer", "toggledText", "simpleText"].string
                        break
                    } else if button["segmentedLikeDislikeButtonViewModel"].exists() { // new button
                        let likeStatus = button["segmentedLikeDislikeButtonViewModel", "likeButtonViewModel", "likeButtonViewModel", "likeStatusEntity", "likeStatus"].stringValue
                        if isAccountConnected {
                            switch likeStatus {
                            case "LIKE":
                                toReturn.authenticatedInfos?.likeStatus = .liked
                            case "DISLIKE":
                                toReturn.authenticatedInfos?.likeStatus = .disliked
                            default:
                                toReturn.authenticatedInfos?.likeStatus = .nothing
                            }
                        }
                        toReturn.likesCount.defaultState = button["segmentedLikeDislikeButtonViewModel", "likeCountEntity", "likeCountIfLiked", "content"].string ?? /* usually because there is no account connected */ button["segmentedLikeDislikeButtonViewModel", "likeButtonViewModel", "likeButtonViewModel", "toggleButtonViewModel", "toggleButtonViewModel", "defaultButtonViewModel", "buttonViewModel", "title"].string
                        toReturn.likesCount.clickedState = button["segmentedLikeDislikeButtonViewModel", "likeCountEntity", "likeCountIfIndifferent", "content"].string ?? /* usually because there is no account connected */ button["segmentedLikeDislikeButtonViewModel", "likeButtonViewModel", "likeButtonViewModel", "toggleButtonViewModel", "toggleButtonViewModel", "toggledButtonViewModel", "buttonViewModel", "title"].string
                        break
                    }
                }
            } else if contentPart["videoSecondaryInfoRenderer"].exists() {
                let videoSecondaryInfos = contentPart["videoSecondaryInfoRenderer"]
                if videoSecondaryInfos["owner"].exists() {
                    let channel = videoSecondaryInfos["owner", "videoOwnerRenderer"]
                    if let channelId = channel["title", "runs", 0, "navigationEndpoint", "browseEndpoint", "browseId"].string {
                        var videoChannel = YTChannel(channelId: channelId)
                        videoChannel.name = channel["title", "runs", 0, "text"].string
                        YTThumbnail.appendThumbnails(json: channel["thumbnail"], thumbnailList: &videoChannel.thumbnails)
                        videoChannel.subscriberCount = channel["subscriberCountText", "simpleText"].string
                        toReturn.channel = videoChannel
                    } else if let channelId = videoSecondaryInfos["owner", "videoOwnerRenderer", "title", "runs", 0, "navigationEndpoint", "showDialogCommand", "panelLoadingStrategy", "inlineContent", "dialogViewModel", "customContent", "listViewModel", "listItems", 0, "listItemViewModel", "title", "commandRuns", 0, "onTap", "innertubeCommand", "browseEndpoint", "browseId"].string {
                        // case where there's mutliple collaborators on a video
                        // TODO: support mutliple channels
                        let channelContent = videoSecondaryInfos["owner", "videoOwnerRenderer", "title", "runs", 0, "navigationEndpoint", "showDialogCommand", "panelLoadingStrategy", "inlineContent", "dialogViewModel", "customContent", "listViewModel", "listItems", 0, "listItemViewModel"]
                        var channel = YTChannel(name: channelContent["title", "content"].string, channelId: channelId)
                        YTThumbnail.appendThumbnails(json: channelContent["leadingAccessory", "avatarViewModel"], thumbnailList: &channel.thumbnails)
                        
                        toReturn.channel = channel
                    }
                }
                if isAccountConnected {
                    toReturn.authenticatedInfos?.subscriptionStatus = videoSecondaryInfos["subscribeButton", "subscribeButtonRenderer", "subscribed"].bool
                }
                if videoSecondaryInfos["attributedDescription"].exists() {
                    var videoDescription: [YouTubeDescriptionPart] = []
                    var lastDecodedPartEndTextIndex: Int = 0
                    let descriptionText = videoSecondaryInfos["attributedDescription", "content"].stringValue
                    for partRole in videoSecondaryInfos["attributedDescription", "commandRuns"].arrayValue {
                        var descriptionPart = YouTubeDescriptionPart()
                        if let beginning = partRole["startIndex"].int, let lenght = partRole["length"].int {
                            if beginning != lastDecodedPartEndTextIndex {
                                /// There is a text with no links inside that we need to add here.
                                var newPart = YouTubeDescriptionPart()
                                if descriptionText.count > beginning {
                                    let substringBeginning = descriptionText.index(descriptionText.startIndex, offsetBy: lastDecodedPartEndTextIndex)
                                    let substringEnd = descriptionText.index(descriptionText.startIndex, offsetBy: beginning - 1)
                                    newPart.text = String(descriptionText[substringBeginning...substringEnd])
                                }
                                videoDescription.append(newPart)
                                lastDecodedPartEndTextIndex = beginning
                            }
                            if descriptionText.count >= beginning + lenght {
                                let substringBeginning = descriptionText.index(descriptionText.startIndex, offsetBy: beginning)
                                let substringEnd = descriptionText.index(descriptionText.startIndex, offsetBy: beginning + lenght)
                                descriptionPart.text = String(descriptionText[substringBeginning..<substringEnd])
                                lastDecodedPartEndTextIndex = beginning + lenght
                            }
                        }
                        if let linkURL = partRole["onTap", "innertubeCommand", "urlEndpoint", "url"].url {
                            descriptionPart.role = .link(linkURL)
                            descriptionPart.style = .blue
                        } else if let videoId = partRole["onTap", "innertubeCommand", "watchEndpoint", "videoId"].string {
                            if partRole["onTap", "innertubeCommand", "watchEndpoint", "continuePlayback"].boolValue {
                                descriptionPart.role = .video(videoId)
                                descriptionPart.style = .custom
                            } else if let chapterTime = partRole["onTap", "innertubeCommand", "watchEndpoint", "startTimeSeconds"].int {
                                descriptionPart.role = .chapter(chapterTime)
                                descriptionPart.style = .blue
                            }
                        } else if let channelOrPlaylistId = partRole["onTap", "innertubeCommand", "browseEndpoint", "browseId"].string {
                            if channelOrPlaylistId.hasPrefix("UC") {
                                descriptionPart.role = .channel(channelOrPlaylistId)
                                descriptionPart.style = .custom
                            } else if channelOrPlaylistId.hasPrefix("VL") {
                                descriptionPart.role = .playlist(channelOrPlaylistId)
                                descriptionPart.style = .custom
                            }
                        }
                        videoDescription.append(descriptionPart)
                    }
                    toReturn.videoDescription = videoDescription
                }
            } else if contentPart["itemSectionRenderer"].exists() {
                for content in contentPart["itemSectionRenderer", "contents"].arrayValue {
                    if content["commentsEntryPointHeaderRenderer"].exists() {
                        toReturn.commentsCount = content["commentsEntryPointHeaderRenderer", "commentCount", "simpleText"].string
                        var teaserCommentAvatar: [YTThumbnail] = []
                        YTThumbnail.appendThumbnails(json: content["commentsEntryPointHeaderRenderer", "contentRenderer", "commentsEntryPointTeaserRenderer", "teaserAvatar"], thumbnailList: &teaserCommentAvatar)
                        toReturn.teaserComment.avatar = teaserCommentAvatar
                        toReturn.teaserComment.teaserText = content["commentsEntryPointHeaderRenderer", "contentRenderer", "commentsEntryPointTeaserRenderer", "teaserContent", "simpleText"].string
                    } else if contentPart["itemSectionRenderer", "targetId"].string == "comments-section" {
                        toReturn.commentsContinuationToken = content["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string
                    }
                }
            }
        }
        
        for engagementPanel in json["engagementPanels"].arrayValue {
            /// Chapters extraction.
            if let targetId = engagementPanel["engagementPanelSectionListRenderer", "targetId"].string, (targetId == "engagement-panel-macro-markers-auto-chapters" || targetId == "engagement-panel-macro-markers-description-chapters") {
                var chapterstoReturn: [Chapter] = []
                for chapterJSON in engagementPanel["engagementPanelSectionListRenderer", "content", "macroMarkersListRenderer", "contents"].arrayValue {
                    var chapter = Chapter()
                    chapter.title = chapterJSON["macroMarkersListItemRenderer", "title", "simpleText"].string
                    
                    YTThumbnail.appendThumbnails(json: chapterJSON["macroMarkersListItemRenderer", "thumbnail"], thumbnailList: &chapter.thumbnail)
                    
                    chapter.startTimeSeconds = chapterJSON["macroMarkersListItemRenderer", "onTap", "watchEndpoint", "startTimeSeconds"].int
                    
                    chapter.timeDescriptions.shortTimeDescription = chapterJSON["macroMarkersListItemRenderer", "timeDescription", "simpleText"].string
                    
                    chapter.timeDescriptions.textTimeDescription = chapterJSON["macroMarkersListItemRenderer", "timeDescriptionA11yLabel"].string
                    
                    chapterstoReturn.append(chapter)
                }
                toReturn.chapters = chapterstoReturn
                break
            }
        }
        
        for recommendation in json["contents", "twoColumnWatchNextResults", "secondaryResults", "secondaryResults", "results"].arrayValue {
            if recommendation["lockupViewModel"].exists() {
                if let decodedVideo = YTVideo.decodeLockupJSON(json: recommendation["lockupViewModel"]) {
                    toReturn.recommendedVideos.append(decodedVideo)
                }
            } else if recommendation["itemSectionRenderer", "contents"].exists() {
                for element in recommendation["itemSectionRenderer", "contents"].arrayValue {
                    if element["lockupViewModel"].exists() {
                        if let decodedVideo = YTVideo.decodeLockupJSON(json: element["lockupViewModel"]) {
                            toReturn.recommendedVideos.append(decodedVideo)
                        }
                    } else if element["compactVideoRenderer", "videoId"].exists() {
                        if let decodedVideo = YTVideo.decodeJSON(json: element["compactVideoRenderer"]) {
                            toReturn.recommendedVideos.append(decodedVideo)
                        }
                    } else if let continuationToken = element["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                        toReturn.recommendedVideosContinuationToken = continuationToken
                    }
                }
            } else if recommendation["compactVideoRenderer", "videoId"].exists(), let decodedVideo = YTVideo.decodeJSON(json: recommendation["compactVideoRenderer"]) {
                toReturn.recommendedVideos.append(decodedVideo)
            } else if let continuationToken = recommendation["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                toReturn.recommendedVideosContinuationToken = continuationToken
            }
        }
        
        if toReturn.recommendedVideosContinuationToken == nil {
            for continuation in json["contents", "twoColumnWatchNextResults", "secondaryResults", "secondaryResults", "continuations"].arrayValue {
                if let continuationToken = continuation["nextContinuationData", "continuation"].string {
                    toReturn.recommendedVideosContinuationToken = continuationToken
                    break
                }
            }
        }
        
        // Sometimes, YouTube inverts the likesCount's defaultState and likeState
        
        if let likesCountNonClickedString = toReturn.likesCount.defaultState, let likesCountClickedString = toReturn.likesCount.clickedState, let likesCountNonClicked = Int(likesCountNonClickedString), let likesCountClicked = Int(likesCountClickedString) {
            toReturn.likesCount.defaultState = likesCountClicked > likesCountNonClicked ? likesCountNonClickedString : likesCountClickedString
            toReturn.likesCount.clickedState = likesCountClicked > likesCountNonClicked ? likesCountClickedString : likesCountNonClickedString
        }
        
        return toReturn
    }
    
    /// Merge the continuation results of the recommended videos.
    ///
    /// - Parameter continuation: The continuation to merge.
    public mutating func mergeRecommendedVideosContination(_ continuation: RecommendedVideosContinuation) {
        self.recommendedVideos.append(contentsOf: continuation.results)
        self.recommendedVideosContinuationToken = continuation.continuationToken
    }
    
    /// Get the continuation of the recommended videos.
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter result: the closure to execute when the request is finished.
    ///
    /// - Note: using cookies with this request is generally not needed.
    public func getRecommendedVideosContination(youtubeModel: YouTubeModel, result: @escaping @Sendable (Result<RecommendedVideosContinuation, Error>) -> ()) {
        if let recommendedVideosContinuationToken = recommendedVideosContinuationToken {
            RecommendedVideosContinuation.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.continuation: recommendedVideosContinuationToken], result: result)
        } else {
            result(.failure("recommendedVideosContinuationToken of the MoreVideoInfosResponse is nil."))
        }
    }
    
    /// Get the continuation of the recommended videos.
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Returns: A ``MoreVideoInfosResponse/RecommendedVideosContinuation`` or an error.
    ///
    /// - Note: using cookies with this request is generally not needed.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func getRecommendedVideosContinationThrowing(youtubeModel: YouTubeModel) async throws -> RecommendedVideosContinuation {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<RecommendedVideosContinuation, Error>) in
            getRecommendedVideosContination(youtubeModel: youtubeModel, result: { result in
                continuation.resume(with: result)
            })
        })
    }
    
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use getRecommendedVideosContination(youtubeModel: YouTubeModel, result: @escaping (Result<RecommendedVideosContinuation, Error>) -> ()) instead.") // safer and better to use the Result API instead of a tuple
    /// Get the continuation of the recommended videos.
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Parameter result: the closure to execute when the request is finished.
    ///
    /// - Note: using cookies with this request is generally not needed.
    public func getRecommendedVideosContination(youtubeModel: YouTubeModel, result: @escaping @Sendable (RecommendedVideosContinuation?, Error?) -> ()) {
        self.getRecommendedVideosContination(youtubeModel: youtubeModel, result: { returning in
            switch returning {
            case .success(let response):
                result(response, nil)
            case .failure(let error):
                result(nil, error)
            }
        })
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of YouTubeKit, please use getRecommendedVideosContination(youtubeModel: YouTubeModel) async throws -> RecommendedVideosContinuation instead.") // safer and better to use the throws API instead of a tuple
    /// Get the continuation of the recommended videos.
    ///
    /// - Parameter youtubeModel: the model to use to execute the request.
    /// - Returns: A ``MoreVideoInfosResponse/RecommendedVideosContinuation`` or an error.
    ///
    /// - Note: using cookies with this request is generally not needed.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func getRecommendedVideosContination(youtubeModel: YouTubeModel) async -> (RecommendedVideosContinuation?, Error?) {
        do {
            return await (try self.getRecommendedVideosContinationThrowing(youtubeModel: youtubeModel), nil)
        } catch {
            return (nil, error)
        }
    }
    
    
    /// Struct representing the continuation of the recommended videos of the ``MoreVideoInfosResponse``.
    public struct RecommendedVideosContinuation: ResponseContinuation {
        public static let headersType: HeaderTypes = .fetchMoreRecommendedVideosHeaders
        
        public static let parametersValidationList: ValidationList = [.continuation: .existenceValidator]
        
        public var continuationToken: String?
        
        public var results: [any YTSearchResult] = []
        
        public static func decodeJSON(json: JSON) -> RecommendedVideosContinuation {
            var toReturn = RecommendedVideosContinuation()
            
            for action in json["onResponseReceivedEndpoints"].arrayValue {
                if action["appendContinuationItemsAction"].exists() {
                    for element in action["appendContinuationItemsAction", "continuationItems"].arrayValue {
                        if element["compactVideoRenderer", "videoId"].exists(), let decodedVideo = YTVideo.decodeJSON(json: element["compactVideoRenderer"]) {
                            toReturn.results.append(decodedVideo)
                        } else if element["lockupViewModel", "contentType"].string == "LOCKUP_CONTENT_TYPE_VIDEO", let decodedVideo = YTVideo.decodeLockupJSON(json: element["lockupViewModel"]) {
                            toReturn.results.append(decodedVideo)
                        } else if let continuationToken = element["continuationItemRenderer", "continuationEndpoint", "continuationCommand", "token"].string {
                            toReturn.continuationToken = continuationToken
                        }
                    }
                }
            }
            
            return toReturn
        }
    }
    
    /// Struct representing the data about the video that concerns the account that was used to make the requests (the cookies).
    public struct AuthenticatedData: Codable, Sendable {
        public init(likeStatus: YTLikeStatus? = nil, subscriptionStatus: Bool? = nil) {
            self.likeStatus = likeStatus
            self.subscriptionStatus = subscriptionStatus
        }
        
        @available(*, deprecated, message: "This init will be removed in a future YouTubeKit version, please use YTLikeStatus instead.")
        public init(likeStatus: LikeStatus? = nil, subscriptionStatus: Bool? = nil) {
            let realLikeStatus: YTLikeStatus? = {
                switch likeStatus {
                case .liked:
                    return .liked
                case .disliked:
                    return .disliked
                case .nothing:
                    return .nothing
                case .none:
                    return nil
                }
            }()

            self.likeStatus = realLikeStatus
            self.subscriptionStatus = subscriptionStatus
        }
        
        /// Like status for the video of the account.
        public var likeStatus: YTLikeStatus?
        
        /// Boolean indicating whether the account is subscribed to the channel that posted the video or not.
        public var subscriptionStatus: Bool?
        
        /// Enum representing the different "appreciation" status of the account for the video.
        @available(*, deprecated, message: "This enum will be removed in a future YouTubeKit version, please use YTLikeStatus instead.")
        public enum LikeStatus: Codable, Sendable {
            case liked
            case disliked
            case nothing
        }
    }
    
    /// Struct representing a part of the video's description.
    public struct YouTubeDescriptionPart: Codable, Sendable {
        public init(text: String? = nil, role: YouTubeDescriptionPartRole? = nil, style: YouTubeDescriptionPartStyle = .normalText) {
            self.text = text
            self.role = role
            self.style = style
        }
        
        /// Text of the part.
        public var text: String?
        
        /// Role of the description part.
        public var role: YouTubeDescriptionPartRole?
        
        /// Style of the description part.
        public var style: YouTubeDescriptionPartStyle = .normalText
        
        /// Enum representing the different description part roles that the text could have.
        public enum YouTubeDescriptionPartRole: Codable, Sendable {
            /// Contains the URL of the link.
            case link(URL)
            
            /// Contains the start time in seconds of the chapter.
            case chapter(Int)
            
            /// Contains the channel's id.
            case channel(String)
            
            /// Contains the video's id.
            case video(String)
            
            /// Contains the playlist's id.
            case playlist(String)
        }
        
        /// Style that this part adopts on YouTube's website.
        public enum YouTubeDescriptionPartStyle: Codable, Sendable {
            case normalText
            case blue
            
            /// YouTube provides a custom UI for links that point to other YouTube content.
            case custom
        }
    }
    
    /// Struct representing a chapter of the video.
    public struct Chapter: Codable, Sendable {
        public init(title: String? = nil, thumbnail: [YTThumbnail] = [], startTimeSeconds: Int? = nil, timeDescriptions: (shortTimeDescription: String?, textTimeDescription: String?) = (nil, nil)) {
            self.title = title
            self.thumbnail = thumbnail
            self.startTimeSeconds = startTimeSeconds
            self.timeDescriptions = timeDescriptions
        }
        
        /// Title of the chapter.
        public var title: String?
        
        /// Thumbnail representing the chapter.
        ///
        /// Generally a screenshot of the video at the beginning of the chapter.
        public var thumbnail: [YTThumbnail] = []
        
        /// Start time in seconds of the chapter.
        public var startTimeSeconds: Int?
        
        /// Two times descriptions of the chapter.
        ///
        /// `shortTimeDescription` could be "0:00" and `textTimeDescription` could be "0 second".
        public var timeDescriptions: (shortTimeDescription: String?, textTimeDescription: String?)
        
        
        // Codable Conformance
        enum CodingKeys: String, CodingKey {
            case title
            case thumbnail
            case startTimeSeconds
            case shortTimeDescription
            case textTimeDescription
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            title = try container.decodeIfPresent(String.self, forKey: .title)
            thumbnail = try container.decodeIfPresent([YTThumbnail].self, forKey: .thumbnail) ?? []
            startTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .startTimeSeconds)
            timeDescriptions.shortTimeDescription = try container.decodeIfPresent(String?.self, forKey: .shortTimeDescription) ?? nil
            timeDescriptions.textTimeDescription = try container.decodeIfPresent(String?.self, forKey: .textTimeDescription) ?? nil
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(title, forKey: .title)
            try container.encode(thumbnail, forKey: .thumbnail)
            try container.encode(startTimeSeconds, forKey: .startTimeSeconds)
            try container.encode(timeDescriptions.shortTimeDescription, forKey: .shortTimeDescription)
            try container.encode(timeDescriptions.textTimeDescription, forKey: .textTimeDescription)
        }
    }
}
