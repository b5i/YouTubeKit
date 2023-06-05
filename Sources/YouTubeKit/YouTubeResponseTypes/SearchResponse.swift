//
//  SearchResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// The string value of the YTSearchResultTypes are the HTML renderer values in YouTube's API response
public enum YTSearchResultType: String, Codable, CaseIterable {
    /// Types represents the string value of their distinguished JSON dictionnary's name.
    case video = "videoRenderer"
    case channel = "channelRenderer"
    case playlist = "playlistRenderer"
    //case visitorData
    
    /// Get the struct that has to be use to decode a particular item.
    static func getDecodingStruct(forType type: Self) -> (any YTSearchResult.Type) {
        switch type {
        case .video:
            return Video.self
        case .channel:
            return Channel.self
        case .playlist:
            return Playlist.self
        }
    }
    
    /// Struct representing a video.
    public struct Video: YTSearchResult, Codable {
        public static func decodeJSON(json: JSON) -> Video {
            /// Inititalize a new ``YTSearchResultType/Video-swift.struct`` instance to put the informations in it.
            var video = Video()
            
            if json["title"]["simpleText"].string != nil {
                video.title = json["title"]["simpleText"].string
            } else {
                video.title = json["title"]["runs"][0]["text"].string
            }
            
            video.channel.name = json["ownerText"]["runs"][0]["text"].string
            video.channel.browseId = json["ownerText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string
            
            if let viewCount = json["shortViewCountText"]["simpleText"].string {
                video.viewCount = viewCount
            } else {
                var viewCount: String = ""
                for viewCountTextPart in json["shortViewCountText"]["runs"].array ?? [] {
                    viewCount += viewCountTextPart["text"].string ?? ""
                }
                video.viewCount = viewCount
            }
            
            video.timePosted = json["publishedTimeText"]["simpleText"].string
            
            if let timeLength = json["lengthText"]["simpleText"].string {
                video.timeLength = timeLength
            } else {
                video.timeLength = "live"
            }
            
            appendThumbnails(json: json, thumbnailList: &video.thumbnails)
            
            return video
        }
        
        public static var type: YTSearchResultType = .video
        
        public var id: Int?
        
        /// String identifier of the video, can be used to get the formats of the video.
        ///
        /// For example:
        ///
        ///     let video: Video = ...
        ///     if let videoId = video.videoId {
        ///         sendRequest(responseType: FormatsResponse.self, query: video.videoId, result: { result, error in
        ///             print(result)
        ///             print(error)
        ///         })
        ///     }
        public var videoId: String?
        
        /// Video's title.
        public var title: String?
        
        /// Channel informations.
        ///
        /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
        public var channel: Channel.LittleChannelInfos = .init()
        
        /// Number of views of the video, in a shortened string.
        ///
        /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
        public var viewCount: String?
        
        /// String representing the moment when the video was posted.
        ///
        /// Usually like `posted 3 months ago`.
        ///
        /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
        public var timePosted: String?
        
        /// String representing the duration of the video.
        ///
        /// Can be `live` instead of `ab:cd` if the video is a livestream.
        public var timeLength: String?
        
        /// Array of thumbnails.
        ///
        /// Usually sorted by resolution, from low to high.
        ///
        /// Possibly not defined when reading in ``YTSearchResultType/Playlist-swift.struct/frontVideos`` properties.
        public var thumbnails: [Thumbnail] = []
        
        ///Not necessary here because of prepareJSON() method
        /*
        enum CodingKeys: String, CodingKey {
            case videoId
            case title
            case channel
            case viewCount
            case timePosted
            case timeLength
            case thumbnails
        }
         */
    }
    
    /// Struct representing a channel.
    public struct Channel: YTSearchResult {
        public static func decodeJSON(json: JSON) -> Channel {
            /// Inititalize a new ``YTSearchResultType/Channel-swift.struct`` instance to put the informations in it.
            var channel = Channel()
            channel.name = json["title"]["simpleText"].string
            
            channel.browseId = json["channelId"].string
            
            appendThumbnails(json: json, thumbnailList: &channel.thumbnails)
            
            /// There's an error in YouTube's API
            channel.subscriberCount = json["videoCountText"]["simpleText"].string
            
            if let badgesList = json["ownerBadges"].array {
                for badge in badgesList {
                    if let badgeName = badge["metadataBadgeRenderer"]["style"].string {
                        channel.badges.append(badgeName)
                    }
                }
            }
            
            return channel
        }
        
        public static var type: YTSearchResultType = .channel
        
        public var id: Int?
        
        /// Channel's name.
        public var name: String?
        
        /// Channel's identifier, can be used to get the informations about the channel.
        ///
        /// For example:
        /// ```
        /// let channel: Channel = ...
        /// if let channelId = channel.browseId {
        ///     sendRequest(responseType: ChannelInfos.self, browseId: channelId, params: ("Kind of the wanted informations // (TODO) need to create an enum with the possibilites"), result: { result, error in
        ///         print(result)
        ///         print(error)
        ///     })
        /// }
        /// ```
        public var browseId: String?
        
        /// Array of thumbnails representing the avatar of the channel.
        ///
        /// Usually sorted by resolution, from low to high.
        public var thumbnails: [Thumbnail] = []
        
        /// Channel's subscribers count.
        ///
        /// Usually like "123k subscribers".
        public var subscriberCount: String?
        
        /// Array of string identifiers of the badges that a channel has.
        ///
        /// Usually like "BADGE_STYLE_TYPE_VERIFIED
        public var badges: [String] = []
        
        ///Not necessary here because of prepareJSON() method
        /*
        enum CodingKeys: String, CodingKey {
            case name
            case stringIdentifier
            case thumbnails
            case subscriberCount
            case badges
        }
         */
        
        /// Structure found in search requests in **video** and **playlist** types.
        public struct LittleChannelInfos: Codable {
            /// Name of the owning channel.
            public var name: String? = ""
            
            /// Channel's identifier, can be used to get the informations about the channel.
            ///
            /// For example:
            /// ```
            /// let channel: Channel = ...
            /// if let channelId = channel.browseId {
            ///     sendRequest(responseType: ChannelInfos.self, browseId: channelId, params: ("Kind of the wanted informations // (TODO) need to create an enum with the possibilites"), result: { result, error in
            ///         print(result)
            ///         print(error)
            ///     })
            /// }
            /// ```
            public var browseId: String? = ""
        }
    }

    /// Struct representing a playlist.
    public struct Playlist: YTSearchResult {
        public static func decodeJSON(json: JSON) -> Playlist {
            /// Inititalize a new ``YTSearchResultType/Playlist-swift.struct`` instance to put the informations in it.
            var playlist = Playlist()
            playlist.title = json["title"]["simpleText"].string
            
            appendThumbnails(json: json["thumbnailRenderer"]["playlistVideoThumbnailRenderer"]["thumbnail"], thumbnailList: &playlist.thumbnails)
                        
            playlist.videoCount = ""
            for videoCountTextPart in json["videoCountText"]["runs"].array ?? [] {
                playlist.videoCount! += videoCountTextPart["text"].string ?? ""
            }
            
            playlist.channel.name = ""
            for channelNameTextPart in json["longBylineText"]["runs"].array ?? [] {
                playlist.channel.name! += channelNameTextPart["text"].string ?? ""
            }
            
            playlist.channel.browseId = json["longBylineText"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string
            
            playlist.timePosted = json["publishedTimeText"]["simpleText"].string
            
            for frontVideoIndex in 0..<(json["videos"].array?.count ?? 0) {
                playlist.frontVideos.append(
                    Video.decodeJSON(json: json["videos"][frontVideoIndex]["childVideoRenderer"])
                )
            }
            
            return playlist
        }
        
        public static var type: YTSearchResultType = .playlist
        
        public var id: Int?
        
        /// Playlist's identifier, can be used to get the informations about the channel.
        ///
        /// For example:
        /// ```
        /// let playlist: Playlist = ...
        /// if let playlistId = playlist.playlistId {
        ///     sendRequest(responseType: PlaylistInfos.self, browseId: playlistId, result: { result, error in
        ///         print(result)
        ///         print(error)
        ///     })
        /// }
        /// ```
        public var playlistId: String?
        
        /// Title of the playlist.
        public var title: String?
        
        /// Array of thumbnails.
        ///
        /// Usually sorted by resolution, from low to high.
        public var thumbnails: [Thumbnail] = []
        
        /// A string representing the number of video in the playlist.
        public var videoCount: String?

        /// Channel informations.
        public var channel: Channel.LittleChannelInfos = .init()
        
        /// String representing the moment when the video was posted.
        ///
        /// Usually like `posted 3 months ago`.
        public var timePosted: String?
        
        /// An array of videos that are contained in the playlist, usually the first ones.
        public var frontVideos: [Video] = []
        
        ///Not necessary here because of prepareJSON() method
        /*
        enum CodingKeys: String, CodingKey {
            case playlistId
            case title
            case thumbnails
            case thumbnails
            case videoCount
            case channel
            case timePosted
            case frontVideos
        }
         */
    }
    
    /// Struct representing a thumbnail.
    public struct Thumbnail: Codable {
        /// Width of the image.
        public var width: Int?
        
        /// Height of the image.
        public var height: Int?
        
        /// URL of the image.
        public var url: URL
    }
    
    
    /// Append to  `[Thumbnail]` another `[Thumbnail]` from JSON.
    /// - Parameters:
    ///   - json: the JSON of the thumbnails.
    ///   - thumbnailList: the array of `Thumbnail` where the ones in the given JSON have to be appended.
    static func appendThumbnails(json: JSON, thumbnailList: inout [Thumbnail]) {
        for thumbnail in json["thumbnail"]["thumbnails"].array ?? [] {
            if let url = thumbnail["url"].url {
                thumbnailList.append(
                    Thumbnail(
                        width: thumbnail["width"].int,
                        height: thumbnail["height"].int,
                        url: url
                    )
                )
            }
        }
    }
}

/// Protocol representing a search result.
public protocol YTSearchResult: Codable {
    /// Defines the item's type, for example a video or a channel
    ///
    /// You can filter array of YTSearchResult conform items using
    ///
    ///     var array: [any YTSearchResult] = ...
    ///     array.filterTypes(acceptedTypes: [.video])
    ///
    /// to get videos only for example.
    static var type: YTSearchResultType { get }
    
    /// Decode and process the JSON from Data, and give a decoded version of it..
    /// - Parameter data: the JSON encoded in Data.
    /// - Returns: an instance of the decoded JSON object.
    static func decodeJSON(data: Data) -> Self
    
    /// Process the JSON and give a decoded version of it.
    /// - Parameter json: the JSON that has to be decoded.
    /// - Returns: an instance of the decoded JSON object.
    static func decodeJSON(json: JSON) -> Self
    
    /// Identifier of the item in the request result array, useful when you want to display all your results in the right order.
    /// Has to be defined during the array push operation.
    var id: Int? { get set }
}

public extension YTSearchResult {
    static func decodeJSON(data: Data) -> Self {
        return decodeJSON(json: JSON(data))
    }
}

public extension [YTSearchResult] {
    /// Making easier to filter item types of your array
    func filterTypes(acceptedTypes: [YTSearchResultType] = YTSearchResultType.allCases) -> [YTSearchResult] {
        return self.filter({acceptedTypes.contains(type(of: $0).type)})
    }
}

public struct SearchResponse: YouTubeResponse {
    public static var headersType: HeaderTypes = .search
    
    public var continuationToken: String = ""
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
    
    static func decodeResults(results: [JSON], searchResponse: inout SearchResponse) {
        for resultElement in results {
            guard let castedElement = getCastedResultElement(element: resultElement) else { continue } //continue if element type is not handled
            searchResponse.results.append(castedElement)
        }
    }
    
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
    
    static func getResultElementType(element: JSON) -> YTSearchResultType? {
        for searchResultType in YTSearchResultType.allCases {
            if element[searchResultType.rawValue].dictionary != nil {
                return searchResultType
            }
        }
        return nil
    }
}
