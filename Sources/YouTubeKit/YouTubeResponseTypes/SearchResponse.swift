//
//  SearchResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 03.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

///The string value of the YTSearchResultTypes are the HTML renderer values in YouTube's API response
public enum YTSearchResultType: String, Codable, CaseIterable {
    case video = "videoRenderer"
    case channel = "channelRenderer"
    case playlist = "playlistRenderer"
    //case visitorData
    
    static func getDecodingClass(forType type: Self) -> (any YTSearchResult.Type) {
        switch type {
        case .video:
            return Video.self
        case .channel:
            return Channel.self
        case .playlist:
            return Playlist.self
        }
    }
    
    public struct Video: YTSearchResult, Codable {
        public static func decodeJSON(json: JSON) -> Video {
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
        
        public var videoId: String?
        public var title: String?
        public var channel: Channel.LittleChannelInfos = .init()
        public var viewCount: String?
        public var timePosted: String?
        public var timeLength: String?
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
    
    public struct Channel: YTSearchResult {
        public static func decodeJSON(json: JSON) -> Channel {
            var channel = Channel()
            channel.name = json["title"]["simpleText"].string
            
            channel.browseId = json["channelId"].string
            
            appendThumbnails(json: json, thumbnailList: &channel.thumbnails)
            
            
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
        
        public var name: String?
        public var browseId: String?
        public var thumbnails: [Thumbnail] = []
        public var subscriberCount: String?
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
        
        public struct LittleChannelInfos: Codable {
            public var name: String? = ""
            public var browseId: String? = ""
        }
    }

    public struct Playlist: YTSearchResult {
        public static func decodeJSON(json: JSON) -> Playlist {
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
        
        public var playlistId: String?
        public var title: String?
        public var thumbnails: [Thumbnail] = []
        public var videoCount: String?
        public var channel: Channel.LittleChannelInfos = .init()
        public var timePosted: String?
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
    
    public struct Thumbnail: Codable {
        public var width: Int?
        public var height: Int?
        public var url: URL
    }
    
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

public protocol YTSearchResult: Codable {
    static var type: YTSearchResultType { get }
    static func decodeJSON(data: Data) -> Self
    static func decodeJSON(json: JSON) -> Self
    var id: Int? { get set }
}


public extension YTSearchResult {
    static func decodeJSON(data: Data) -> Self {
        return decodeJSON(json: JSON(data))
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
                    .getDecodingClass(forType: castedElementType)
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
