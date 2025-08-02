//
//  HistoryBlockContent.swift
//
//
//  Created by Antoine Bollengier on 16.03.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier. All rights reserved.
//  

import Foundation

/// A protocol describing some content from an ``HistoryResponse/HistoryBlock``
public protocol HistoryBlockContent: Hashable, Sendable {
    var id: Int { get }
}
