//
//  EndScreenElement.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 11.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation

public struct EndScreenElement: Sendable {
    public var type: ElementType

    /// Start time in milliseconds where the element appears.
    public var startTime: Int
    
    /// End time in milliseconds where the element appears.
    public var endTime: Int
    
    /// Position of the element on the screen, all values are in percentage (0.0 - 1.0) relative to the video size.
    ///
    /// For example,  an origin.x of 0.3 means the element starts at 30% of the video width from the left.
    public var position: CGRect
    
    public enum ElementType: Sendable {
        case video(video: YTVideo)
        case playlist(playlist: YTPlaylist)
        
        /// - Note: If `subscribeButton` is true, that means a subscribe button is shown instead of the description.
        case channel(channel: YTChannel, subscribeButton: Bool, description: String?)
        case link(link: Link)
        
        public struct Link: Sendable {
            public var url: URL
            public var title: String?
            public var thumbnail: [YTThumbnail]
        }
    }
    
    public init?(fromEndscreenElementRenderer json: JSON){
        guard let style = json["style"].string,
                let x = json["left"].double,
                let y = json["top"].double,
                let width = json["width"].double,
                let aspectRatio = json["aspectRatio"].double,
                let startTime = Int(json["startMs"].stringValue),
                let endTime = Int(json["endMs"].stringValue),
              let type: ElementType = {
                  switch style {
                  case "VIDEO":
                      guard let videoId = json["endpoint", "watchEndpoint", "videoId"].string else { return nil }
                      
                      var video = YTVideo(videoId: videoId)
                      video.title = json["title", "runs"].arrayValue.map { $0["text"].stringValue }.joined()
                      video.viewCount = json["metadata", "runs", 0, "text"].string
                      video.timeLength = json["thumbnailOverlays", 0, "thumbnailOverlayTimeStatusRenderer", "text", "runs", 0, "text"].string
                      YTThumbnail.appendThumbnails(json: json["image"], thumbnailList: &video.thumbnails)
                      
                      return .video(video: video)
                  case "PLAYLIST":
                      guard let playlistId = json["endpoint", "watchEndpoint", "playlistId"].string else { return nil }
                      
                      var playlist = YTPlaylist(playlistId: playlistId)
                      playlist.title = json["title", "runs"].arrayValue.map { $0["text"].stringValue }.joined()
                      playlist.videoCount = json["playlistLength", "runs", 0, "text"].string
                      YTThumbnail.appendThumbnails(json: json["image"], thumbnailList: &playlist.thumbnails)
                      
                      return .playlist(playlist: playlist)
                  case "CHANNEL":
                      guard let channelId = json["endpoint", "browseEndpoint", "browseId"].string else { return nil }
                      
                      var channel = YTChannel(channelId: channelId)
                      channel.name = json["title", "runs"].arrayValue.map { $0["text"].stringValue }.joined()
                      YTThumbnail.appendThumbnails(json: json["image"], thumbnailList: &channel.thumbnails)
                      channel.subscriberCount = json["subscribersText", "runs", 0, "text"].string ?? json["metadata", "runs", 0, "text"].string
                      
                      let subscribeButton = json["isSubscribe"].boolValue
                      
                      return .channel(channel: channel, subscribeButton: subscribeButton, description: subscribeButton ? nil : json["metadata", "runs"].arrayValue.map { $0["text"].stringValue }.joined())
                  case "WEBSITE":
                      guard let bloatedUrl = json["endpoint", "urlEndpoint", "url"].url,
                            let urlString = URLComponents(url: bloatedUrl, resolvingAgainstBaseURL: false)?.queryItems?.first(where: {$0.name == "q"})?.value,
                            let url = URL(string: urlString)
                      else { return nil }
                      let title = json["title", "runs"].arrayValue.map { $0["text"].stringValue }.joined()
                      let thumbnail = YTThumbnail.getThumbnails(json: json["image"])
                      return .link(link: .init(url: url, title: title, thumbnail: thumbnail))
                  default:
                      return nil
                  }
              }()
        
        else { return nil }
        
        self.type = type
        self.position = CGRect(x: x, y: y, width: width, height: width / (aspectRatio + 0.001))
        self.startTime = startTime
        self.endTime = endTime
    }
}
