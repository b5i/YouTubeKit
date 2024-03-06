//
//  RequestLogger+defaultImplementations.swift
//  
//
//  Created by Antoine Bollengier on 06.03.2024.
//

import Foundation

public extension RequestsLogger {
    func startLogging() {
        self.isLogging = true
    }
    
    func stopLogging() {
        self.isLogging = false
    }
    
    
    func addLog(_ log: RequestLog) {
        if self.isLogging {
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
}
