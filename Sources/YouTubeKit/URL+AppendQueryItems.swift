//
//  URL+AppendQueryItems.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 19.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

public extension URL {
    ///adapted from https://stackoverflow.com/questions/34060754/how-can-i-build-a-url-with-query-parameters-containing-multiple-values-for-the-s
    mutating func append(queryItems queryItemsToAdd: [URLQueryItem]) {
        guard var urlComponents = URLComponents(string: self.absoluteString) else { return }
        
        /// Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        
        /// Append the new query item in the existing query items array
        queryItems.append(contentsOf: queryItemsToAdd)
        
        /// Append updated query items array in the url component object
        urlComponents.queryItems = queryItems
        
        /// Returns the url from new url components
        self = urlComponents.url!
    }
}
