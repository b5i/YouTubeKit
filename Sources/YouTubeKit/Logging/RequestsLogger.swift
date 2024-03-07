//
//  RequestsLogger.swift
//  
//
//  Created by Antoine Bollengier on 06.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//

import Foundation

/// A protocol describing a logger that is used by an instance of ``YouTubeModel``.
///
/// You can create a simple logger like this:
/// ```swift
/// class MyLogger: RequestsLogger {
///     var logs: [RequestLog] = []
///
///     var isLogging: Bool = false
///
///     var maximumCacheSize: Int? = nil
/// }
/// ```
/// If you want to use it as a model for a SwiftUI view you can also make a logger that conforms to the ObservableObject protocol:
/// ```swift
/// class MyLogger: RequestsLogger, ObservableObject {
///
///     @Published var logs: [RequestLog] = []
///
///     @Published var isLogging: Bool = false
///
///     var maximumCacheSize: Int? = nil
/// }
/// ```
///
/// And then don't forget to add it to your ``YouTubeModel`` instance:
/// ```swift
/// YTM.logger = MyLogger()
/// ```
///
/// - Note: Be aware that enabling logging can consume a lot of RAM as the logger stores a lot of raw informations. Therefore, make sure that you regularly clear the ``RequestsLogger/logs`` or disable logging when it's not needed.
public protocol RequestsLogger: AnyObject {
    /// An array of logs for requests/responses executed by the ``YouTubeModel``. A log is added once the request is fully finished and processed.
    var logs: [RequestLog] { get set }
    
    /// A boolean indicating whether the logging is active, if it's set to false, no additional logs will be added to the ``RequestsLogger/logs`` array.
    var isLogging: Bool { get set }
    
    /// The maximum amount of logs that the logger should retain, old logs should be deleted first.
    var maximumCacheSize: Int? { get set }
    
    /// Start the logging, has to at least set ``RequestsLogger/isLogging`` to true.
    func startLogging()
    
    /// Start the logging, has to at least set ``RequestsLogger/isLogging`` to false.
    func stopLogging()
    
    
    /// Set the ``RequestsLogger/maximumCacheSize`` to the given size, if it's nil then no limit is applied. Be aware that if the current amount of logs exceeds the new size, the oldest logs will be deleted.
    func setCacheSize(_ size: Int?)
    
    /// Add a log to the logger, shouldn't add a log if ``RequestsLogger/isLogging`` is set to false. Will be called when the response of the request finished processing.
    func addLog(_ log: RequestLog)
    
    /// Clear all the logs from the ``RequestsLogger/logs`` array.
    func clearLogs()
    
    /// Clear all the logs whose id is in the `ids` array.
    func clearLogsWithIds(_ ids: [UUID])
    
    /// Clear the log that has the specified `id`, won't do anything if such log does not exist.
    func clearLogWithId(_ id: UUID)
}
