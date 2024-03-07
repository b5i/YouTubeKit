//
//  RequestLogger+defaultImplementations.swift
//  
//
//  Created by Antoine Bollengier on 06.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension RequestsLogger {
    func startLogging() {
        self.isLogging = true
    }
    
    func stopLogging() {
        self.isLogging = false
    }
    
    
    func setCacheSize(_ size: Int?) {
        self.maximumCacheSize = size
        if var size = size {
            self.removeFirstLogsWith(limit: size)
        }
    }
    
    
    func addLog(_ log: RequestLog) {
        if self.isLogging && (self.maximumCacheSize ?? 1) > 0 {
            if var maximumCacheSize = self.maximumCacheSize {
                self.removeFirstLogsWith(limit: max(maximumCacheSize - 1, 0))
            }
            self.logs.append(log)
        }
    }
    
    
    func clearLogs() {
        self.logs.removeAll()
    }
    
    func clearLogsWithIds(_ ids: [UUID]) {
        for idToRemove in ids {
            self.logs.removeAll(where: {$0.id == idToRemove})
        }
    }
    
    func clearLogWithId(_ id: UUID) {
        self.clearLogsWithIds([id])
    }
    
    private func removeFirstLogsWith(limit maxCacheSize: Int) {
        let logsCount = self.logs.count
        let maxCacheSize = max(0, maxCacheSize)
        if logsCount > maxCacheSize {
            self.logs.removeFirst(abs(maxCacheSize - logsCount))
        }
    }
}
