//
//  Array+inoutMap.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 21.06.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

extension Array {
    mutating func inoutMap(_ body: (inout Element) throws -> Void) rethrows {
        for i in indices {
            try body(&self[i])
        }
    }
}
