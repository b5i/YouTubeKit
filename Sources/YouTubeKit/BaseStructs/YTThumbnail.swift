//
//  YTThumbnail.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Struct representing a thumbnail.
public struct YTThumbnail: Codable, Equatable {
    /// Width of the image.
    public var width: Int?
    
    /// Height of the image.
    public var height: Int?
    
    /// URL of the image.
    public var url: URL
    
    /// Append to  `[Thumbnail]` another `[Thumbnail]` from JSON.
    /// - Parameters:
    ///   - json: the JSON of the thumbnails, of form
    ///    {
    ///     "thumbnail":
    ///         {
    ///             "thumbnails": [thumbnailsHere]
    ///         }
    ///    }
    ///   - thumbnailList: the array of `Thumbnail` where the ones in the given JSON have to be appended.
    public static func appendThumbnails(json: JSON, thumbnailList: inout [YTThumbnail]) {
        for thumbnail in json["thumbnail"]["thumbnails"].array ?? [] {
            if var url = thumbnail["url"].url {
                /// URL is of form "//yt3.googleusercontent.com/ytc"
                if url.absoluteString.prefix(2) == "//" {
                    url = URL(string: "https:\(url.absoluteString)") ?? url
                    thumbnailList.append(
                        YTThumbnail(
                            width: thumbnail["width"].int,
                            height: thumbnail["height"].int,
                            url: url
                        )
                    )
                } else {
                    thumbnailList.append(
                        YTThumbnail(
                            width: thumbnail["width"].int,
                            height: thumbnail["height"].int,
                            url: url
                        )
                    )
                }
            }
        }
    }
}
