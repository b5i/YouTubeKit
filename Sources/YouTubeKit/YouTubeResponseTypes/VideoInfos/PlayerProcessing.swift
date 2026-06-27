//
//  PlayerProcessing.swift
//  YouTubeKit
//
//  Created by Antoine Bollengier on 17.06.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

#if canImport(JavaScriptCore)
import JavaScriptCore
#endif

public enum PlayerProcessing {
    public enum PlayersCache {

        /// Manages in-memory and on-disk caching for YouTube player data.
        ///
        /// - In-memory: Keeps a FIFO list of recently used `Player` instances (`maxCacheSize` is the limit).
        /// - Disk: Persists the cipher decode instructions (`.ab`) and full player JS (`.abn`)
        ///   so that the n-parameter solver can be reconstructed without re-downloading base.js.
        // MARK: - Player cache

        private static var playerCache: [Player] = []

        public static var maxCacheSize = 3 {
            didSet {
                if self.playerCache.count > maxCacheSize {
                    self.playerCache.removeFirst(self.playerCache.count - maxCacheSize)
                }
            }
        }

        /// Retrieve a cached `Player` by its version token (name).
        /// - Parameter name: The player version identifier extracted from the path.
        /// - Returns: A cached `Player` if present in memory, otherwise `nil`.
        public static func getPlayer(withName name: String) -> Player? {
            self.playerCache.first(where: { $0.name == name })
        }

        /// Add a `Player` to the in-memory cache, trimming to `maxCacheSize`.
        /// If a player with the same name already exists, it will not be added.
        public static func addPlayer(_ player: Player) {
            guard !self.playerCache.contains(where: { $0.name == player.name }) else { return }
            
            if self.playerCache.count >= self.maxCacheSize {
                self.playerCache.removeFirst()
            }
            self.playerCache.append(player)
        }

        /// List the names (version tokens) of players currently cached in memory.
        public static func listCachedPlayers() -> [String] {
            self.playerCache.map(\.name)
        }

        /// Remove a specific player from both memory and disk.
        /// - Parameter name: The player version to remove.
        public static func removeCache(forPlayerName name: String) throws {
            self.playerCache.removeAll(where: { $0.name == name })
            try self.removePlayerFilesFromDisk(playerName: name)
        }

        /// Remove all cached players from memory and purge any associated JS solvers.
        ///
        /// Disk artifacts remain in place. To also clear disk, call ``removeAllDiskFiles()``.
        public static func clearCache() throws {
            self.playerCache.removeAll()
            try Self.removeAllDiskFiles()
        }

        // MARK: - Disk persistence

        /// Load cached player data from disk.
        /// - Parameter playerName: The player version token.
        /// - Returns: The decoded instruction list and full player JS if both files are present; otherwise `nil`.
        static func loadFromDisk(playerName: String) -> (instructions: [Player.CipherDecodeInstruction], playerJs: String)? {
            guard
                let documentDirectoryPath = try? getDocumentDirectory(),
                let instructionsData = FileManager.default.contents(
                    atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).ab"),
                let instructions = try? JSONDecoder().decode(
                    [Player.CipherDecodeInstruction].self, from: instructionsData),
                let playerJsData = FileManager.default.contents(
                    atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).abn")
            else { return nil }

            return (instructions, String(decoding: playerJsData, as: UTF8.self))
        }

        /// Persist player instructions (`.ab`) and full JS (`.abn`) to disk.
        /// - Parameters:
        ///   - playerName: Player version token used to name the files.
        ///   - instructions: Cipher decode instructions extracted from the player.
        ///   - playerData: Raw contents of base.js for this player.
        static func saveToDisk(playerName: String, instructions: [Player.CipherDecodeInstruction], playerData: Data) {
            guard let documentDirectoryPath = try? getDocumentDirectory() else { return }
            do {
                FileManager.default.createFile(
                    atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).ab",
                    contents: try JSONEncoder().encode(instructions)
                )
                FileManager.default.createFile(
                    atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).abn",
                    contents: playerData
                )
            } catch {}
        }
        
        /// Remove cached files on disk for a specific player version.
        /// Deletes both `.ab` and `.abn` files associated with `playerName`.
        static func removePlayerFilesFromDisk(playerName: String) throws {
            let playersDirectory = try getDocumentDirectory()
            let url = URL(fileURLWithPath: playersDirectory)
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else { return }
            for case let file as URL in enumerator {
                if file.absoluteString.hasSuffix("YouTubeKitPlayers-\(playerName).ab") || file.absoluteString.hasSuffix("YouTubeKitPlayers-\(playerName).abn") {
                    try FileManager.default.removeItem(at: file)
                }
            }
        }

        /// Remove all `.ab` and `.abn` player files from disk.
        static func removeAllDiskFiles() throws {
            let playersDirectory = try getDocumentDirectory()
            let url = URL(fileURLWithPath: playersDirectory)
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else { return }
            for case let file as URL in enumerator {
                if file.absoluteString.hasSuffix(".ab") || file.absoluteString.hasSuffix(".abn") {
                    try FileManager.default.removeItem(at: file)
                }
            }
        }

        /// Get the documents directory path as a `String`, handling API differences across platforms.
        private static func getDocumentDirectory() throws -> String {
            guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw Player.ResponseError(step: .getDocumentDirectory, reason: "Failed to get the documentsDirectory.")
            }
            if #available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
                return url.path()
            } else {
                return url.path
            }
        }
    }

    public final class Player: Sendable {
        public let name: String
        private let instructions: [CipherDecodeInstruction]
        /// Closure that decodes a single raw n-parameter value.
        /// `nil` on platforms where JavaScriptCore is unavailable.
        #if canImport(JavaScriptCore)
        private let solver: (@Sendable (String) -> String?)?
        #endif

        /// Get (or create) a `Player` for a given player path.
        ///
        /// - Parameter path: The player path as found in the HTML (e.g. `/s/player/.../base.js`).
        /// - Returns: A cached `Player` if available, otherwise a newly constructed one.
        public static func getPlayer(forPath path: String) throws -> Player {
            let name = try Self.getNameFromPath(path)
            if let cachedPlayer = PlayersCache.getPlayer(withName: name) {
                return cachedPlayer
            }

            let newPlayer = try Player(path: path, name: name)
            PlayersCache.addPlayer(newPlayer)
            return newPlayer
        }

        /// Initialize a `Player` by fetching/deriving its decode instructions and n-solver.
        /// - Parameters:
        ///   - path: Full player path extracted from the page.
        ///   - name: Optional pre-extracted player name; if `nil`, the name is derived from `path`.
        private init(path: String, name: String? = nil) throws {
            if let name = name {
                self.name = name
            } else {
                self.name = try Self.getNameFromPath(path)
            }
            // `playerJs` is used only here to build the solver; it is not stored.
            let (instructionArray, playerJs) = try Self.processPlayerScrapping(playerPath: path, playerName: self.name)
            self.instructions = instructionArray
            #if canImport(JavaScriptCore)
            self.solver = JscSolver.makeSolver(playerJs: playerJs, playerName: self.name)
            #endif
        }

        /// Extract the player version token from a player path.
        /// - Parameter path: The raw player path string, `.../s/player/...`.
        /// - Throws: If the version token cannot be found.
        private static func getNameFromPath(_ path: String) throws -> String {
            guard let name = path.ytkFirstGroupMatch(for: "s/player/([^\\s|\\/]*)") else { throw "Can't find player name in path" }
            return name
        }

        /// Decipher a signature-ciphered URL using the extracted instruction sequence.
        /// - Parameter cipher: The raw `signatureCipher` string from the streaming data JSON.
        /// - Returns: A fully formed URL with the signature applied.
        private func decipherFormatURL(signatureCipher cipher: String) throws -> URL {
            guard let url = cipher.ytkFirstGroupMatch(for: "&?url=([^\\s|&]*)")?.removingPercentEncoding else { throw "Can't find URL in cipher" }

            guard var cipherString = cipher.ytkFirstGroupMatch(for: "&?s=([^\\s|&]*)")?.removingPercentEncoding else { throw "Can't find cipher string in cipher" }

            var splittedCipherString = cipherString.map { $0 }

            for instruction in self.instructions {
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

            guard let cipherString = cipherString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { throw "Failed to percent-encode cipher string" }

            var result = "\(url)&sig=\(cipherString)"
            result = result.replacingOccurrences(of: ",", with: "%2C")

            guard let resultURL = URL(string: result) else { throw "Failed to create URL from result string" }

            return resultURL
        }

        /// Process the `n` query parameter using the preprocessed JavaScript solver.
        /// - Parameter url: A URL that may contain a throttling `n` parameter.
        /// - Returns: The same URL with its `n` parameter replaced by the decoded value.
        /// - Throws: If JavaScriptCore is unavailable or decoding fails.
        public func processNParameterInURL(url: URL) throws -> URL {
#if canImport(JavaScriptCore)
            guard var components = URLComponents(string: url.absoluteString),
                  var queryItems = components.queryItems,
                  let rawN = queryItems.first(where: { $0.name == "n" })?.value
            else { return url }
            
            guard let decodedN = self.solver?(rawN) else { throw "Failed to decode n-parameter in URL" }

            queryItems.removeAll(where: { $0.name == "n" })
            queryItems.append(URLQueryItem(name: "n", value: decodedN))
            components.queryItems = queryItems
            guard let decodedURL = components.url else { throw "Failed to construct URL with decoded n-parameter" }
            return decodedURL
#else
            throw "JavaScriptCore not available; cannot process n-parameter"
#endif
        }

        /// Get an updated ``DownloadFormat`` with a fully decoded URL.
        /// - Parameters:
        ///   - item: The partially decoded format item (may already contain a direct `url`).
        ///   - cipher: Optional `signatureCipher` string; if present, it will be deciphered.
        /// - Returns: The same format with its `url` fully processed, including `n`-parameter decoding.
        public func processDownloadFormatURL(item: inout DownloadFormat) throws {
            let url: URL
            if let cipher = item.signatureCipher {
                url = try self.decipherFormatURL(signatureCipher: cipher)
            } else {
                guard let decodedURL = item.url else {
                    return
                }
                url = decodedURL
            }

            item.url = try self.processNParameterInURL(url: url)
        }

        /// Decode the n-parameter embedded in an HLS manifest URL.
        ///
        /// YouTube embeds the n-parameter in HLS manifest URLs as a path segment
        /// rather than a query parameter: `.../n/RAW_VALUE/.../index.m3u8`
        ///
        /// - Parameter urlString: The raw `hlsManifestUrl` string from the streaming data JSON.
        /// - Returns: The manifest URL with the `n` path segment replaced, or the original URL if decoding fails.
        public func decodeNParameterInHLSManifestURL(_ urlString: String) -> URL? {
#if canImport(JavaScriptCore)
            guard
                let regex = try? NSRegularExpression(pattern: #"/n/([^/]+)/"#),
                let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
                let rawNRange = Range(match.range(at: 1), in: urlString)
            else {
                return URL(string: urlString)
            }

            let rawN = String(urlString[rawNRange])

            guard let decodedN = self.solver?(rawN) else {
                return URL(string: urlString)
            }

            let decodedURLString = urlString.replacingCharacters(
                in: urlString.range(of: "/n/\(rawN)/")!,
                with: "/n/\(decodedN)/"
            )
            return URL(string: decodedURLString)
#else
            return URL(string: urlString)
#endif
        }

        // MARK: - Scraping

        /// Get the player's decoding functions to un-throttle download format links download speed.
        /// - Parameters:
        ///   - playerPath: The path of the JavaScript file that represents the player's engine (usually `base.js`).
        ///   - playerName: The player version token.
        /// - Returns: The decoded instruction array and the full player JS content.
        private static func processPlayerScrapping(playerPath: String, playerName: String) throws -> (instructions: [CipherDecodeInstruction], playerJs: String) {
            guard URL(string: "https://youtube.com\(playerPath)") != nil else {
                throw ResponseError(step: .processPlayerScrapping, reason: "Could not create player URL (tried: https://youtube.com\(playerPath)")
            }

            if let cached = PlayersCache.loadFromDisk(playerName: playerName) {
                return cached
            }

            guard let playerURL = URL(string: "https://youtube.com\(playerPath)") else {
                throw ResponseError(step: .processPlayerScrapping, reason: "Could not create player URL (tried: https://youtube.com\(playerPath)")
            }
            return try scrapePlayer(playerName: playerName, playerURL: playerURL)
        }

        /// Scrape functions from the player.
        /// - Parameters:
        ///   - playerName: The player's version name.
        ///   - playerURL: URL pointing to YouTube's player script.
        /// - Returns: The decoded instruction array and the full player JS content.
        private static func scrapePlayer(
            playerName: String,
            playerURL: URL
        ) throws -> (instructions: [CipherDecodeInstruction], playerJs: String) {
            let playerData = try downloadPlayer(playerURL: playerURL)
            let dataString = String(decoding: playerData, as: UTF8.self)
            let separatedByLinePlayer: [String] = dataString.components(separatedBy: .newlines)

            var knownPlayerCipherDecodeInstructions: [String: CipherDecodeInstruction] = [:]
            var instructionsArray: [CipherDecodeInstruction] = []

            for line in separatedByLinePlayer {
                guard let instructionsString = line.ytkFirstGroupMatch(for: #"=function\(.\)\{.=.\.split\(""\);([\s\S]*?)return"#) else { continue }

                let instructionsStringArray = instructionsString.split(separator: ";").map { String($0) }

                for instruction in instructionsStringArray {
                    guard let currentFunctionName = instruction.ytkFirstGroupMatch(for: "\\.([\\S]*?)\\(") else { continue }
                    guard let currentPotentialIntParameter = instruction.ytkFirstGroupMatch(for: "\\([^0-9]*([0-9]*)"),
                          let currentIntParameter = Int(currentPotentialIntParameter) else { continue }

                    if knownPlayerCipherDecodeInstructions[currentFunctionName] == nil {
                        knownPlayerCipherDecodeInstructions[currentFunctionName] = CipherDecodeInstruction.getInstructionTypeByName(
                            currentFunctionName,
                            separatedByLinesPlayerScript: separatedByLinePlayer
                        )
                    }

                    switch knownPlayerCipherDecodeInstructions[currentFunctionName] {
                    case .swap:
                        instructionsArray.append(.swap(currentIntParameter))
                    case .splice:
                        instructionsArray.append(.splice(currentIntParameter))
                    default:
                        instructionsArray.append(knownPlayerCipherDecodeInstructions[currentFunctionName] ?? .unknown)
                    }
                }

                break
            }

            PlayersCache.saveToDisk(playerName: playerName, instructions: instructionsArray, playerData: playerData)

            return (instructionsArray, dataString)
        }

        /// Download the player script.
        /// - Parameter playerURL: The URL of the player script.
        /// - Returns: The raw data for the player JavaScript file.
        private static func downloadPlayer(playerURL: URL) throws -> Data {
            let downloadOperation = DownloadPlayerOperation(playerURL: playerURL)
            downloadOperation.start()
            downloadOperation.waitUntilFinished()

            guard let result = downloadOperation.result else {
                throw ResponseError(step: .downloadPlayer, reason: "Download operation did not return a result.")
            }

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
                    if result != nil { self.task = nil }
                }
            }

            init(playerURL: URL) {
                self.playerURL = playerURL
                super.init()
            }

            override func start() {
                guard !isCancelled else { return }
                let semaphore = DispatchSemaphore(value: 0)
                self.task = URLSession(configuration: .ephemeral).dataTask(with: self.playerURL) { data, _, error in
                    if let data = data {
                        self.result = .success(data)
                    } else {
                        self.result = .failure(error ?? "Player download failed but no error was emitted.")
                    }
                    semaphore.signal()
                }
                self.task?.resume()
                semaphore.wait()
            }
        }

        // MARK: - CipherDecodeInstruction

        /// Enum listing the different operations possible to decode the cipher.
        public enum CipherDecodeInstruction: Codable, Sendable {
            case swap(Int)
            case splice(Int)
            case reverse
            case unknown

            static func getInstructionTypeByName(
                _ name: String,
                separatedByLinesPlayerScript: [String]
            ) -> CipherDecodeInstruction {
                for line in separatedByLinesPlayerScript {
                    if line.contains("\(name):function(") {
                        guard let functionContent = line.ytkFirstGroupMatch(
                            for: "\(name):function\\([^\\{]*\\{([^\\}]*)"
                        ) else { continue }

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

        // MARK: - ResponseError

        public struct ResponseError: Error {
            public let step: StepType
            public let reason: String

            public enum StepType: Sendable {
                case decodeData
                case processPlayerScrapping
                case scrapPlayer
                case downloadPlayer
                case getDocumentDirectory
            }
        }
    }

    // MARK: - JscSolver

#if canImport(JavaScriptCore)
    /// Builds JavaScript solvers for the n-parameter from a full player JS.
    ///
    /// This type is a pure factory — it does not cache. Call-site caching is
    /// handled by higher-level components (e.g., ``PlayersCache``).
    enum JscSolver {

        /// The raw content of `jsc_bundle.js`, loaded once at first use.
        private static let bundleSource: String? = {
            guard
                let url = Bundle.module.url(forResource: "jsc_bundle", withExtension: "js", subdirectory: "JavaScript"),
                let src = try? String(contentsOf: url, encoding: .utf8)
            else {
                assertionFailure("jsc_bundle.js not found in module bundle")
                return nil
            }
            return src
        }()

        /// Builds a JSContext, evaluates the bundle, preprocesses base.js, and returns
        /// a single-argument Swift closure `(rawN) -> processedN?`.
        /// - Parameters:
        ///   - playerJs: Full content of `base.js` for this player version.
        ///   - playerName: Player version token, used only for logging.
        /// - Returns: A closure that decodes a single raw n-parameter value, or `nil` if preprocessing fails.
        static func makeSolver(playerJs: String, playerName: String) -> (@Sendable (String) -> String?)? {
            guard let bundleSource = self.bundleSource else { return nil }

            let ctx = JSContext()
            ctx?.exceptionHandler = { _, exception in
                print("JS exception for player \(playerName): \(exception?.toString() ?? "?")")
            }

            ctx?.evaluateScript(bundleSource)

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

            return { rawN in
                let result = solveFn.call(withArguments: [preprocessedStr, rawN])
                guard result?.isString == true else { return nil }
                return result?.toString()
            }
        }
    }
    #endif // canImport(JavaScriptCore)
}

