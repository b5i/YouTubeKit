//
//  YTPlaylist+decodeShowFromJSON.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 25.06.2023.
//  Copyright © 2023 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension YTPlaylist {
    /// Decode a certain type of playlist named "show", can be recognized because they are stored in dicitonnaries named "gridShowRenderer".
    /// - Parameter json: the JSON representing the **inside** of the "gridShowRenderer".
    /// - Returns: A playlist if the decoding was successful, or nil if it wasn't. You can already know if the decoding is going to be successful using the `canShowBeDecoded` method.
    static func decodeShowFromJSON(json: JSON) -> YTPlaylist? {
        /// Decode the playlist that is named a "show" by YouTube.
        guard let playlistId = json["navigationEndpoint", "browseEndpoint", "browseId"].string else { return nil }
        var playlist = YTPlaylist(playlistId: playlistId.hasPrefix("VL") ? playlistId : "VL" + playlistId)
        playlist.title = json["title", "simpleText"].string
        
        YTThumbnail.appendThumbnails(json: json["thumbnailRenderer", "showCustomThumbnailRenderer", "thumbnail"], thumbnailList: &playlist.thumbnails)
        
        guard let videoCountArray = json["thumbnailOverlays"].array else { return playlist }
        
        for videoCountPotential in videoCountArray {
            if let videoCount = videoCountPotential["thumbnailOverlayBottomPanelRenderer", "text", "simpleText"].string {
                playlist.videoCount = videoCount
            } else if let videoCountTextArray = videoCountPotential["thumbnailOverlayBottomPanelRenderer", "text", "runs"].array {
                playlist.videoCount = videoCountTextArray.map({$0["text"].stringValue}).joined()
            }
        }
        
        return playlist
    }
}
