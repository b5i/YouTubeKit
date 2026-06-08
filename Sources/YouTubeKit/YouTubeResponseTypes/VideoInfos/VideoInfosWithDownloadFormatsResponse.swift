//
//  VideoInfosWithDownloadFormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2026 Antoine Bollengier. All rights reserved.
//

import Foundation
#if canImport(JavaScriptCore)
import JavaScriptCore
//#else
//#if os(Linux)
//import LinuxJavaScriptCore
//#endif
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
import JavaScriptCore
#endif

/// Struct representing the VideoInfosWithDownloadFormatsResponse.
public struct VideoInfosWithDownloadFormatsResponse: YouTubeResponse {
    @available(*, deprecated, message: "Please use the global VideoDownloadFormat instead of VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat")
    public typealias VideoDownloadFormat = YouTubeKit.VideoDownloadFormat
    
    @available(*, deprecated, message: "Please use the global AudioOnlyFormat instead of VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat")
    public typealias AudioOnlyFormat = YouTubeKit.AudioOnlyFormat
    
    public static let headersType: HeaderTypes = .videoInfosWithDownloadFormats
    
    public static let parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    /// Array of formats used to download the video, they usually contain both audio and video data and the download speed is higher than the ``VideoInfosWithDownloadFormatsResponse/downloadFormats``.
    public var defaultFormats: [any DownloadFormat]
    
    /// Array of formats used to download the video, usually sorted from highest video quality to lowest followed by audio formats.
    public var downloadFormats: [any DownloadFormat]
    
    /// Base video infos like if it did a ``VideoInfosResponse`` request.
    public var videoInfos: VideoInfosResponse
    
    public static func decodeData(data: Data) throws -> VideoInfosWithDownloadFormatsResponse {
        /// Special processing for VideoInfosWithDownloadFormatsResponse
        
        /// The received data is not some JSON, it is an HTML file containing the JSON and other relevant informations that are necessary to process the ``DownloadFormat``.
        /// It begins by getting the player version (the player is a JS script used to manage the player on their webpage and it decodes the n-parameter).
        
        let dataToString = String(decoding: data, as: UTF8.self)
        
        /// We have something like this **/s/player/playerId/player_ias.vflset/en_US/base.js**
        guard let playerPath = dataToString.ytkFirstGroupMatch(for: "<link rel=\"preload\" href=\"https:\\/\\/i.ytimg.com\\/generate_204\" as=\"fetch\"><link as=\"script\" rel=\"preload\" href=\"([\\S]+)\"") else {
            throw ResponseError(step: .decodeData, reason: "Couldn't get player path.")
        }
                
        let (instructionArray, playerJs, playerName) = try processPlayerScrapping(playerPath: playerPath)
                
        guard let stringJSONData = dataToString.ytkFirstGroupMatch(for: "var ytInitialPlayerResponse = ([\\S\\s]*\\}\\}\\}\\})[\\S\\s]*;</script><div id=\"player\"") else {
            throw ResponseError(step: .decodeData, reason: "Couldn't get player's JSON data.")
        }
        
        let json = JSON(parseJSON: stringJSONData)
        
        var toReturn = try self.decodeJSON(json: json)
        
        // Extract the default formats.
        
        if let defaultFormatsJSONArray = json["streamingData", "formats"].array {
            toReturn.videoInfos.defaultFormats = convertJSONToDownloadFormats(
                json: defaultFormatsJSONArray,
                instructionsArray: instructionArray,
                playerJs: playerJs,
                playerName: playerName
            )
            toReturn.defaultFormats = toReturn.videoInfos.defaultFormats
        }
        
        // Extract the download formats.
        
        if let downloadFormatsJSONArray = json["streamingData", "adaptiveFormats"].array {
            toReturn.videoInfos.downloadFormats = convertJSONToDownloadFormats(
                json: downloadFormatsJSONArray,
                instructionsArray: instructionArray,
                playerJs: playerJs,
                playerName: playerName
            )
            toReturn.downloadFormats = toReturn.videoInfos.downloadFormats
        }
        
        // The n-parameter in HLS manifest URLs is embedded as a path segment "/n/VALUE/" rather than as a query parameter, so it needs its own handling.
        if let hlsManifestURLString = toReturn.videoInfos.streamingURL?.absoluteString {
            toReturn.videoInfos.streamingURL = decodeNParameterInHLSManifestURL(
                hlsManifestURLString,
                playerJs: playerJs,
                playerName: playerName
            )
        }
        
        return toReturn
    }
    
    /// Function that creates a ``VideoInfosWithDownloadFormatsResponse`` but that fills only the ``VideoInfosWithDownloadFormatsResponse/videoInfos`` entry and let the other propertes to nil/empty values.
    public static func decodeJSON(json: JSON) throws -> VideoInfosWithDownloadFormatsResponse {
        return VideoInfosWithDownloadFormatsResponse(
            defaultFormats: [],
            downloadFormats: [],
            videoInfos: try VideoInfosResponse.decodeJSON(json: json)
        )
    }
    
    /// Get an array of ``DownloadFormat`` from a JSON array.
    /// - Parameters:
    ///   - json: the JSON that has to be decoded.
    ///   - instructionsArray: an array of ``PlayerCipherDecodeInstruction`` that can be precised to avoid reading the encoded file on disk.
    ///   - playerJs: full content of the player's base.js (used to decode the n-parameter).
    ///   - playerName: player version token used as cache key for the n-solver.
    /// - Returns: an array of ``DownloadFormat``.
    private static func convertJSONToDownloadFormats(
        json: [JSON],
        instructionsArray: [PlayerCipherDecodeInstruction],
        playerJs: String,
        playerName: String
    ) -> [DownloadFormat] {
        return json.map({ encodedItem in
            var item = decodeFormatFromJSON(json: encodedItem)
            if let cipher = encodedItem["signatureCipher"].string {
                guard let url = cipher.ytkFirstGroupMatch(for: "&?url=([^\\s|&]*)")?.removingPercentEncoding else { return item }
                                
                guard var cipherString = cipher.ytkFirstGroupMatch(for: "&?s=([^\\s|&]*)")?.removingPercentEncoding else { return item }
                
                var splittedCipherString = cipherString.map { $0 }
                
                for instruction in instructionsArray  {
                    switch instruction {
                    case .swap(let parameter):
                        let tempVar = splittedCipherString[0]
                        splittedCipherString[0] = splittedCipherString[parameter]
                        splittedCipherString[parameter] = tempVar
                    case .splice(let parameter):
                        splittedCipherString = Array(splittedCipherString.dropFirst(parameter))
                    case .reverse:
                        splittedCipherString.reverse()
                    case .unknown:
                        break
                    }
                }
                
                cipherString = String(splittedCipherString)
                
                guard let cipherString = cipherString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return item }
                
                var result = "\(url)&sig=\(cipherString)"
                result = result.replacingOccurrences(of: ",", with: "%2C")
                
                guard let resultURL = URL(string: result) else { return item }
                
                item.url = resultURL
            } else {
                item.url = encodedItem["url"].url
            }
            
            /// Process the n-parameter
#if canImport(JavaScriptCore)
            guard
                var components = URLComponents(string: item.url?.absoluteString ?? ""),
                var queryItems = components.queryItems,
                let rawN = queryItems.first(where: { $0.name == "n" })?.value,
                let decodedN = JscSolver.solveN(rawN: rawN, playerJs: playerJs, playerName: playerName)
            else { return item }
            
            queryItems.removeAll(where: { $0.name == "n" })
            queryItems.append(URLQueryItem(name: "n", value: decodedN))
            components.queryItems = queryItems
            item.url = components.url
#endif
            return item
        })
    }
    
    /// Decode the n-parameter embedded in an HLS manifest URL.
    ///
    /// YouTube embeds the n-parameter in HLS manifest URLs as a **path segment**
    /// rather than a query parameter: `.../n/RAW_VALUE/.../index.m3u8`
    ///
    /// - Parameters:
    ///   - urlString:  The raw `hlsManifestUrl` string from the streaming data JSON.
    ///   - playerJs:   Full text of base.js for this player version.
    ///   - playerName: Player version token used as cache key for the n-solver.
    /// - Returns: The manifest URL with the n path segment replaced, or the original URL if decoding fails.
    private static func decodeNParameterInHLSManifestURL(
        _ urlString: String,
        playerJs: String,
        playerName: String
    ) -> URL? {
#if canImport(JavaScriptCore)
        guard let regex = try? NSRegularExpression(pattern: #"/n/([^/]+)/"#),
              let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
              let rawNRange = Range(match.range(at: 1), in: urlString)
        else {
            return URL(string: urlString)
        }
        
        let rawN = String(urlString[rawNRange])
        
        guard let decodedN = JscSolver.solveN(rawN: rawN, playerJs: playerJs, playerName: playerName) else {
            return URL(string: urlString)
        }
        
        // Replace only the n path segment, leaving the rest of the URL intact.
        let decodedURLString = urlString.replacingCharacters(
            in: urlString.range(of: "/n/\(rawN)/")!,
            with: "/n/\(decodedN)/"
        )
        return URL(string: decodedURLString)
#else
        return URL(string: urlString)
#endif
    }
    
    /// Get the player's decoding functions to un-throttle download format links download speed.
    /// - Parameters:
    ///  - playerPath: The path of the Javascript file that represent the player's engine, usually like **base.js** on YouTube's website.
    ///  - Returns: a closure potentially containing an array of ``PlayerCipherDecodeInstruction``,
    ///             the full player JS content, and the player version name.
    private static func processPlayerScrapping(playerPath: String) throws -> (instructions: [PlayerCipherDecodeInstruction], playerJs: String, playerName: String) {
        guard let playerURL = URL(string: "https://youtube.com\(playerPath)") else { throw ResponseError(step: .processPlayerScrapping, reason: "Could not create player URL (tried: https://youtube.com\(playerPath)") }

        guard let playerName = playerPath.ytkFirstGroupMatch(for: "s/player/([^\\s|\\/]*)") else { throw ResponseError(step: .processPlayerScrapping, reason: "Could not get player name.") }
        
        let documentDirectoryPath: String
        
        if #available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            documentDirectoryPath = try getDocumentDirectory().path()
        } else {
            documentDirectoryPath = try getDocumentDirectory().path
        }
        
        if
            let savedPlayerInstructionsData = FileManager.default.contents(atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).ab"),
            let savedPlayerInstructions = try? JSONDecoder().decode([PlayerCipherDecodeInstruction].self, from: savedPlayerInstructionsData),
            let savedPlayerJsData = FileManager.default.contents(atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).abn")
        {
            let savedPlayerJs = String(decoding: savedPlayerJsData, as: UTF8.self)
            return (savedPlayerInstructions, savedPlayerJs, playerName)
        } else {
            let scrapPlayerResult = try scrapePlayer(playerName: playerName, playerURL: playerURL)
            return scrapPlayerResult
        }
    }
    
    /// Scrape functions from the player
    /// - Parameters:
    ///   - playerName: the player's name.
    ///   - playerURL: player's URL (should point to YouTube's website)
    private static func scrapePlayer(
        playerName: String,
        playerURL: URL
    ) throws -> (instructions: [PlayerCipherDecodeInstruction], playerJs: String, playerName: String) {
        let playerData = try downloadPlayer(playerURL: playerURL)
        let dataString = String(decoding: playerData, as: UTF8.self)
        /// Separate the data by line.
        let separatedByLinePlayer: [String] = dataString.components(separatedBy: .newlines)
        
        /// Dictionnary containing the names of the PlayerCipherDecodeInstruction in the player's code and link them with their corresponding PlayerCipherDecodeInstruction.
        var knownPlayerCipherDecodeInstructions: [String : PlayerCipherDecodeInstruction] = [:]
        
        var instructionsArray: [PlayerCipherDecodeInstruction] = []
        
        for line in separatedByLinePlayer {
            guard let instructionsString = line.ytkFirstGroupMatch(for: #"=function\(.\)\{.=.\.split\(""\);([\s\S]*?)return"#) else { continue }
            
            let instructionsStringArray = instructionsString.split(separator: ";").map { String($0) } // not using components(...), so we don't have an empty item at the end of the array
            
            for instruction in instructionsStringArray {
                guard let currentFunctionName = instruction.ytkFirstGroupMatch(for: "\\.([\\S]*?)\\(") else { continue }
                
                guard let currentPotentialIntParameter = instruction.ytkFirstGroupMatch(for: "\\([^0-9]*([0-9]*)"), let currentIntParameter = Int(currentPotentialIntParameter) else { continue }
                
                if knownPlayerCipherDecodeInstructions[currentFunctionName] == nil {
                    knownPlayerCipherDecodeInstructions[currentFunctionName] = PlayerCipherDecodeInstruction.getInstructionTypeByName(
                        currentFunctionName, separatedByLinesPlayerScript:
                            separatedByLinePlayer
                    )
                }
                
                switch knownPlayerCipherDecodeInstructions[currentFunctionName] {
                case .swap(_):
                    instructionsArray.append(.swap(currentIntParameter))
                case .splice(_):
                    instructionsArray.append(.splice(currentIntParameter))
                default:
                    instructionsArray.append(knownPlayerCipherDecodeInstructions[currentFunctionName] ?? .unknown)
                }
            }

            break
        }
            let documentDirectoryPath: String
            
            if #available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
                documentDirectoryPath = try getDocumentDirectory().path()
            } else {
                documentDirectoryPath = try getDocumentDirectory().path
            }
                do {
                FileManager.default.createFile(
                    atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).ab",
                    contents: try JSONEncoder().encode(instructionsArray)
                )
                
                // Store the full player JS so we can reconstruct the n-solver after a cold start without downloading it again
                // Note: Previously this stored only the extracted n-param processing snippet, but with the new obfuscation techniques, it has become very complicated to isolate the challenge functions
                FileManager.default.createFile(
                    atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).abn",
                    contents: playerData
                )
            } catch {}
        return (instructionsArray, dataString, playerName)
    }
    
    /// Download the player with its URL.
    /// - Parameters:
    ///   - playerURL: URL of the player
    /// - Returns: either Data or a String representing the error depending on the download successfulness.
    private static func downloadPlayer(playerURL: URL) throws -> Data {
        let downloadOperation = DownloadPlayerOperation(playerURL: playerURL)
        downloadOperation.start()
        downloadOperation.waitUntilFinished()
        
        guard let result = downloadOperation.result else { throw ResponseError(step: .downloadPlayer, reason: "Download operation did not return a result.") }
        
        switch result {
        case .success(let success):
            return success
        case .failure(let error):
            throw ResponseError(step: .downloadPlayer, reason: "DownloadOperation failed with error: \(error)")
        }
    }
    
    /// Operation used to download the player.
    private final class DownloadPlayerOperation: Operation, @unchecked Sendable {
        override var isAsynchronous: Bool { true }
        
        override var isExecuting: Bool { result == nil }
        
        override var isFinished: Bool { !isExecuting }
        
        private let playerURL: URL
        
        private var task: URLSessionDataTask?
        
        var result: Result<Data, Error>? {
            didSet {
                if result != nil {
                    self.task = nil
                }
            }
        }
        
        init(playerURL: URL) {
            self.playerURL = playerURL
            super.init()
        }
        
        override func start() {
            guard !isCancelled else { return }
            let semaphore = DispatchSemaphore(value: 0)
            self.task = URLSession(configuration: .ephemeral).dataTask(with: self.playerURL, completionHandler: {
                data, response, error in
                if let data = data {
                    self.result = .success(data)
                } else {
                    self.result = .failure(error ?? "Player download failed but no error was emitted.")
                }
                semaphore.signal()
            })
            self.task?.resume()
            semaphore.wait()
        }
    }
    
    /// Enum listing the different operations possible to decode the cipher.
    private enum PlayerCipherDecodeInstruction: Codable {
        case swap(Int)
        case splice(Int)
        case reverse
        case unknown
        
        /// Search in the player's code for the function's declaration and determine the instruction type of it.
        /// - Parameters:
        ///   - name: name of the function.
        ///   - playerScript: Javascript code of the player.
        /// - Returns: The type of instruction that correspond with the name.
        static func getInstructionTypeByName(_ name: String, separatedByLinesPlayerScript: [String]) -> PlayerCipherDecodeInstruction {
            
            for line in separatedByLinesPlayerScript {
                if line.contains("\(name):function(") {
                    guard let functionContent = line.ytkFirstGroupMatch(for: "\(name):function\\([^\\{]*\\{([^\\}]*)") else { continue }
                    
                    /// Functions types
                    ///
                    /// The function can take one of those three forms:
                    ///
                    ///    This one exchanges the first and the (b+1)-th character
                    ///    ```javascript
                    ///    function(a, b) {
                    ///        var c = a[0];
                    ///        a[0] = a[b % a.length];
                    ///        a[b % a.length] = c
                    ///    }
                    ///    ```
                    ///
                    ///    This one removes the b first characters
                    ///    ```javascript
                    ///    function(a, b) {
                    ///         a.splice(0, b)
                    ///    }
                    ///    ```
                    ///
                    ///    This one reverses the order of the string (now an array)
                    ///    ```javascript
                    ///    function(a) {
                    ///         a.reverse()
                    ///    }
                    ///    ```
                    if functionContent.contains("var c=a[0]") {
                        return .swap(-1)
                    } else if functionContent.contains("a.splice(0,b)") {
                        return .splice(-1)
                    } else if functionContent.contains("a.reverse()") {
                        return .reverse
                    } else {
                        return .unknown
                    }
                }
            }
            return .unknown
        }
    }
    
    /// Decode a ``DownloadFormat`` base informations from a JSON instance.
    /// - Parameter json: the JSON to be decoded.
    /// - Returns: A ``DownloadFormat``.
    static func decodeFormatFromJSON(json: JSON) -> DownloadFormat {
        if json["fps"].int != nil {
            /// Will return an instance of ``VideoInfosWithDownloadFormatsResponse/VideoDownloadFormat``
            return YouTubeKit.VideoDownloadFormat(
                averageBitrate: json["averageBitrate"].int,
                contentDuration: {
                    if let approxDurationMs = json["approxDurationMs"].string {
                        return Int(approxDurationMs)
                    } else {
                        return nil
                    }
                }(),
                contentLength: {
                    if let contentLength = json["contentLength"].string {
                        return Int(contentLength)
                    } else {
                        return nil
                    }
                }(),
                is360: json["projectionType"].string == "MESH",
                isCopyrightedMedia: json["signatureCipher"].string != nil,
                mimeType: json["mimeType"].string?.ytkFirstGroupMatch(for: "([^;]*)"),
                codec: json["mimeType"].string?.ytkFirstGroupMatch(for: #"codecs="([^\.]+)"#),
                url: json["signatureCipher"].string == nil ? json["url"].url : nil,
                width: json["width"].int,
                height: json["height"].int,
                quality: json["qualityLabel"].string,
                fps: json["fps"].int
            )
        } else {
            /// Will return an instance of ``VideoInfosWithDownloadFormatsResponse/AudioOnlyFormat``
            return YouTubeKit.AudioOnlyFormat(
                averageBitrate: json["averageBitrate"].int,
                contentLength: {
                    if let contentLength = json["contentLength"].string {
                        return Int(contentLength)
                    } else {
                        return nil
                    }
                }(),
                contentDuration: {
                    if let approxDurationMs = json["approxDurationMs"].string {
                        return Int(approxDurationMs)
                    } else {
                        return nil
                    }
                }(),
                isCopyrightedMedia: json["signatureCipher"].string != nil,
                url: json["signatureCipher"].string == nil ? json["url"].url : nil,
                mimeType: json["mimeType"].string?.ytkFirstGroupMatch(for: "([^;]*)"),
                codec: json["mimeType"].string?.ytkFirstGroupMatch(for: #"codecs="([^\.]+)"#),
                audioSampleRate: {
                    if let audioSampleRate = json["audioSampleRate"].string {
                        return Int(audioSampleRate)
                    } else {
                        return nil
                    }
                }(),
                loudness: json["loudnessDb"].double,
                formatLocaleInfos: json["audioTrack", "id"].string != nil ? .init(displayName: json["audioTrack", "displayName"].string, localeId: json["audioTrack", "id"].string, isDefaultAudioFormat: json["audioTrack", "audioIsDefault"].bool, isAutoDubbed: json["audioTrack", "isAutoDubbed"].bool) : nil
            )
        }
    }
    
    /// Remove all player mappings from disk and living memory
    public static func removePlayersCache() throws {
#if canImport(JavaScriptCore)
        JscSolver.clearCache()
#endif
        let playersDirectory = try getDocumentDirectory()
        let filesInDir = FileManager.default.enumerator(at: playersDirectory, includingPropertiesForKeys: nil)
        guard let filesInDir = filesInDir else { return }
        for file in filesInDir {
            if let file = file as? URL {
                if file.absoluteString.hasSuffix(".ab") || file.absoluteString.hasSuffix(".abn") {
                    try FileManager.default.removeItem(at: file)
                }
            }
        }
    }
    
    /// Remove all player mappings from disk and living memory
    @available(*, deprecated, renamed: "removePlayersCache")
    public static func removePlayerFilesFromDisk() throws {
        try self.removePlayersCache()
    }
    
    /// Remove all player mappings from disk and living memory, does not throw
    @available(*, deprecated, renamed: "removePlayersCache")
    public static func removePlayersFromDisk() {
        do {
            try self.removePlayersCache()
        } catch {}
    }
    
    /// Get the document directory from the project that is using ``YouTubeKit``
    /// - Returns: The URL of this document directory.
    private static func getDocumentDirectory() throws -> URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { throw ResponseError(step: .getDocumentDirectory, reason: "Failed to get the documentsDirectory.") }
        return url
    }
    
    public struct ResponseError: Error {
        /// The step where the error occured.
        public let step: StepType
        
        /// A string explaining the reason why the error was thrown.
        public let reason: String
        
        public enum StepType: Sendable {
            case decodeData
            case processPlayerScrapping
            case scrapPlayer
            case downloadPlayer
            case getDocumentDirectory
        }
    }
    
    /// Holds one preprocessed JSContext solver per player version so base.js is only parsed once per player release (typically every few days).
    #if canImport(JavaScriptCore)
    private enum JscSolver {

        private static let queue = DispatchQueue(label: "com.youtubekit.jscsolver")

        /// playerName -> Swift closure (preprocessedPlayer already captured inside)
        private static var cache: [String: (String) -> String?] = [:]

        /// The raw content of jsc_bundle.js, loaded once at first use.
        private static let bundleSource: String? = {
            
            guard
                let url = Bundle.module.url(forResource: "jsc_bundle", withExtension: "js", subdirectory: "Resources"),
                let src = try? String(contentsOf: url, encoding: .utf8)
            else {
                assertionFailure("jsc_bundle.js not found in module bundle")
                return nil
            }
            return src
        }()

        /// Process a single `n` value using the given player.
        /// - Parameters:
        ///   - rawN:       The raw n-parameter string
        ///   - playerJs:   Full content of base.js for this player version.
        ///   - playerName: Version name from the player path (e.g. `"5cabb421"`).
        /// - Returns: The decoded n string, or `nil` on any failure.
        static func solveN(rawN: String, playerJs: String, playerName: String) -> String? {
            queue.sync {
                if cache[playerName] == nil {
                    cache[playerName] = makeSolver(playerJs: playerJs, playerName: playerName)
                }
                return cache[playerName]?(rawN)
            }
        }

        /// Drop stale in-memory solvers.
        static func clearCache() {
            queue.sync { cache.removeAll() }
        }

        /// Builds a JSContext, evaluates the bundle, preprocesses base.js, and returns
        /// a single-argument Swift closure `(rawN) -> processedN?`.
        private static func makeSolver(playerJs: String, playerName: String) -> ((String) -> String?)? {
            guard let bundleSource = self.bundleSource else { return nil }

            let ctx = JSContext()
            ctx?.exceptionHandler = { _, exception in
                print("JS exception for player \(playerName): \(exception?.toString() ?? "?")")
            }

            // Load the self-contained bundle
            ctx?.evaluateScript(bundleSource)

            // Preprocess player: AST-parse base.js and extract the n-solver, using yt-dlp project solution
            // Result is a large JS string we keep alive inside the closure below.
            guard
                let preprocessFn = ctx?.objectForKeyedSubscript("jscPreprocessPlayer"),
                let preprocessed  = preprocessFn.call(withArguments: [playerJs]),
                preprocessed.isString,
                let preprocessedStr = preprocessed.toString()
            else {
                print("Failed to preprocess player \(playerName)")
                return nil
            }

            guard
                let solveFn = ctx?.objectForKeyedSubscript("jscSolveNFromPreprocessed"),
                solveFn.isUndefined == false
            else { return nil }

            // Capture ctx, solveFn, and preprocessedStr in the closure so they stay alive.
            return { rawN in
                let result = solveFn.call(withArguments: [preprocessedStr, rawN])
                guard result?.isString == true else { return nil }
                return result?.toString()
            }
        }
    }
    #endif // canImport(JavaScriptCore)
}
