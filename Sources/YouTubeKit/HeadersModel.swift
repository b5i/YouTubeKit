//
//  HeadersModel.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// Used to configure the request to the YouTube API
public class HeadersModel {
    public static let shared = HeadersModel()
    
    /// Set the locale you want to receive the call responses in.
    public var selectedLocale: String = Locale.preferredLanguages[0]
    
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
}
