//
//  VideoInfosWithDownloadFormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 - 2024 Antoine Bollengier. All rights reserved.
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
    public static var headersType: HeaderTypes = .videoInfosWithDownloadFormats
    
    public static var parametersValidationList: ValidationList = [.query: .videoIdValidator]
    
    /// Array of formats used to download the video, they usually contain both audio and video data and the download speed is higher than the ``VideoInfosWithDownloadFormatsResponse/downloadFormats``.
    public var defaultFormats: [any DownloadFormat]
    
    /// Array of formats used to download the video, usually sorted from highest video quality to lowest followed by audio formats.
    public var downloadFormats: [any DownloadFormat]
    
    /// Base video infos like if it did a ``VideoInfosResponse`` request.
    public var videoInfos: VideoInfosResponse
    
    public static func decodeData(data: Data) throws -> VideoInfosWithDownloadFormatsResponse {
        ///Special processing for VideoInfosWithDownloadFormatsResponse
        
        /// The received data is not some JSON, it is an HTML file containing the JSON and other relevant informations that are necessary to process the ``DownloadFormat``.
        /// It begins by getting the player version (the player is a JS script used to manage the player on their webpage and it decodes the n-parameter).
        
        let dataToString = String(decoding: data, as: UTF8.self)
        
        let preparedStringForPlayerId: [String] = dataToString.components(separatedBy: "<link rel=\"preload\" href=\"https://i.ytimg.com/generate_204\" as=\"fetch\"><link as=\"script\" rel=\"preload\" href=\"")
        
        guard preparedStringForPlayerId.count > 1 else { throw ResponseError(step: .decodeData, reason: "Couldn't get player path.") }
        
        /// We have something like this **/s/player/playerId/player_ias.vflset/en_US/base.js**
        let playerPath: String = preparedStringForPlayerId[1].components(separatedBy: "\" nonce=\"")[0]
        
        let (instructionArray, nParameter) = try processPlayerScrapping(playerPath: playerPath)
        var preparedStringForJSONData: [String] = dataToString.components(separatedBy: "var ytInitialPlayerResponse = ")
        
        guard preparedStringForJSONData.count > 1 else { throw ResponseError(step: .decodeData, reason: "Couldn't get player's JSON data.") }
        
        preparedStringForJSONData = preparedStringForJSONData[1].components(separatedBy: ";</script><div id=\"player\"")
        
        preparedStringForJSONData = (preparedStringForJSONData[0] + ";") // We add a ";" so then when we look for "}}}};" we get at least one result.
            .components(separatedBy: "}}}};")
        
        let stringJSONData = preparedStringForJSONData[0] + "}}}}" // As we removed them in the split operation.
        
        let json = JSON(parseJSON: stringJSONData)
        
        var toReturn = self.decodeJSON(json: json)
        
        // Extract the default formats.
        
        if let downloadFormatsJSONArray = json["streamingData"]["formats"].array {
            toReturn.defaultFormats = convertJSONToDownloadFormats(
                json: downloadFormatsJSONArray,
                instructionsArray: instructionArray,
                nParameterString: nParameter
            )
        }
        
        // Extract the download formats.
        
        if let downloadFormatsJSONArray = json["streamingData"]["adaptiveFormats"].array {
            toReturn.downloadFormats = convertJSONToDownloadFormats(
                json: downloadFormatsJSONArray,
                instructionsArray: instructionArray,
                nParameterString: nParameter
            )
        }
        return toReturn
    }
    
    /// Function that creates a ``VideoInfosWithDownloadFormatsResponse`` but that fills only the ``VideoInfosWithDownloadFormatsResponse/videoInfos`` entry and let the other propertes to nil/empty values.
    public static func decodeJSON(json: JSON) -> VideoInfosWithDownloadFormatsResponse {
        return VideoInfosWithDownloadFormatsResponse(defaultFormats: [], downloadFormats: [], videoInfos: VideoInfosResponse.decodeJSON(json: json))
    }
    
    /// Get an array of ``DownloadFormat`` from a JSON array.
    /// - Parameters:
    ///   - json: the JSON that has to be decoded.
    ///   - instructionsArray: an array of ``PlayerCipherDecodeInstruction`` that can be precised to avoid reading the encoded file on disk.
    ///   - nParameterString: a string representing the Javascript code of the nParameter function that can be precised to avoid reading the encoded file on disk.
    /// - Returns: an array of ``DownloadFormat``.
    private static func convertJSONToDownloadFormats(
        json: [JSON],
        instructionsArray: [PlayerCipherDecodeInstruction],
        nParameterString: String
    ) -> [DownloadFormat] {
        return json.map({ encodedItem in
            var item = decodeFromJSON(json: encodedItem)
            if encodedItem["signatureCipher"].string != nil {
                let cipher: String = encodedItem["signatureCipher"].stringValue
                let urlPart: [String] = cipher.components(separatedBy: "&url=")
                
                guard urlPart.count > 1 else { return item }
                
                let url = urlPart[1].removingPercentEncoding
                
                let cipherStringPart = cipher.components(separatedBy: "s=")
                
                guard cipherStringPart.count > 1 else { return item }
                
                let cipherString = cipherStringPart[1].components(separatedBy: "&sp=sig")[0].removingPercentEncoding
                
                guard var cipherString = cipherString else { return item }
                
                var splittedCipherString = cipherString.map { String($0) }
                
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
                
                cipherString = splittedCipherString.joined()
                
                guard let url = url, let cipherString = cipherString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return item }
                
                var result = "\(url)&sig=\(cipherString)"
                result = result.replacingOccurrences(of: ",", with: "%2C")
                
                guard let resultURL = URL(string: result) else { return item }
                
                item.url = resultURL
            } else {
                item.url = encodedItem["url"].url
            }
            
            /// Process the n-parameter
#if canImport(JavaScriptCore)
            guard let urlComponents = URLComponents(string: item.url?.absoluteString ?? "") else { return item }
            
            var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
            
            let nParameter = queryItems.first(where: {$0.name == "n"})?.value
            queryItems.removeAll(where: {$0.name == "n"})
            
            guard let nParameter = nParameter else { return item }
            
            //verify if path is / ok
            let context = JSContext()
            
            guard let context = context else { return item }
            
            context.evaluateScript(nParameterString)
            
            let testFunction = context.objectForKeyedSubscript("processNParameter")
            let result = testFunction?.call(withArguments: [nParameter])
            
            guard let result = result, result.isString, let result = result.toString() else { return item }
            
            item.url?.append(queryItems: [
                URLQueryItem(name: "n", value: result)
            ])
#endif
            return item
        })
    }
    
    /// Extract the nParameter Javascript function from YouTube's player code.
    /// - Parameter textString: YouTube's player code.
    /// - Returns: The Javascript code in Data format.
    private static func extractNParameterFunction(fromFileText textString: String) -> Data {
        
        let textStringParts: [String] = textString
            .replacingOccurrences(of: "\n", with: "")
            .components(separatedBy: "var b=a.split(\"\")")
        guard textStringParts.count > 1 else { return Data() }
        
        return ("function processNParameter(a) { var b=a.split(\"\")" + textStringParts[1].components(separatedBy: "return b.join(\"\")")[0] + ";return b.join(\"\"); }").data(using: .utf8) ?? Data()
    }
    
    /// Get the player's decoding functions to un-throttle download format links download speed.
    /// - Parameters:
    ///  - playerPath: The path of the Javascript file that represent the player's engine, usually like **base.js** on YouTube's website.
    ///  - Returns: a closure potentially containing an array of ``PlayerCipherDecodeInstruction`` and a string representing the nParameter function in Javascript code.
    private static func processPlayerScrapping(playerPath: String) throws -> (instructions: [PlayerCipherDecodeInstruction], nParameterCode: String) {
        guard let playerURL = URL(string: "https://youtube.com\(playerPath)") else { throw ResponseError(step: .processPlayerScrapping, reason: "Could not create player URL (tried: https://youtube.com\(playerPath)") }
        var preparedStringForPlayerName: [String] = playerPath.components(separatedBy: "s/player/")
        
        guard preparedStringForPlayerName.count > 1 else { throw ResponseError(step: .processPlayerScrapping, reason: "Could not get player name.") }
        
        preparedStringForPlayerName = preparedStringForPlayerName[1].components(separatedBy: "/")
        
        let playerName = preparedStringForPlayerName[0]
        
        let documentDirectoryPath: String
        
        if #available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            documentDirectoryPath = try getDocumentDirectory().path()
        } else {
            documentDirectoryPath = try getDocumentDirectory().path
        }
        
        if
            let savedPlayerInstructionsData = FileManager.default.contents(atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).ab"),
            let savedPlayerIntructions = try? JSONDecoder().decode([PlayerCipherDecodeInstruction].self, from: savedPlayerInstructionsData),
            let savedPlayerCodeData = FileManager.default.contents(atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).abn")
        {
            let savedPlayerCode = String(decoding: savedPlayerCodeData, as: UTF8.self)
            return (savedPlayerIntructions, savedPlayerCode)
        } else {
            let scrapPlayerResult = try scrapPlayer(playerName: playerName, playerURL: playerURL)
            return scrapPlayerResult
        }
    }
    
    /// Scrap functions from the player
    /// - Parameters:
    ///   - playerName: the player's name.
    ///   - playerURL: player's URL (should point to YouTube's website)
    ///   - done: a closure potentially containing an array of ``PlayerCipherDecodeInstruction`` and a string representing the nParameter function in Javascript code.
    private static func scrapPlayer(
        playerName: String,
        playerURL: URL
    ) throws -> (instructions: [PlayerCipherDecodeInstruction], nParameterCode: String) {
        let playerData = try downloadPlayer(playerURL: playerURL)
        let dataString = String(decoding: playerData, as: UTF8.self)
        /// Separate the data by line.
        let separatedByLinePlayer: [String] = dataString.components(separatedBy: .newlines)
        
        /// Dictionnary containing the names of the PlayerCipherDecodeInstruction in the player's code and link them with their corresponding PlayerCipherDecodeInstruction.
        var knownPlayerCipherDecodeInstructions: [String : PlayerCipherDecodeInstruction] = [:]
        
        var instructionsArray: [PlayerCipherDecodeInstruction] = []
        
        var nParameterFunction: String? = nil
        
        for line in separatedByLinePlayer {
            if line.contains("a=a.split(\"\");") {
                let functionArray: [String] = line.components(separatedBy: "=function(a){a=a.split(\"\");")
                
                guard functionArray.count > 1 else { throw ResponseError(step: .scrapPlayer, reason: "Could not get n-parameter instructions.") }
                var instructionsString: String = functionArray[1]
                //var functionName: String = functionArray[0]
                
                instructionsString = instructionsString.components(separatedBy: "return a.join(\"\")};")[0]
                
                let instructionsStringArray = instructionsString.split(separator: ";")
                
                for instruction in instructionsStringArray {
                    var preparedCurrentInstructionName = instruction.components(separatedBy: "(a,")
                    guard preparedCurrentInstructionName.count > 1 else { continue }
                    
                    guard let currentIntParameter = Int(preparedCurrentInstructionName[1].components(separatedBy: ")")[0]) else { continue }
                    
                    preparedCurrentInstructionName = preparedCurrentInstructionName[0].components(separatedBy: ".")
                    guard preparedCurrentInstructionName.count > 1 else { continue }
                    
                    let currentFunctionName = preparedCurrentInstructionName.last
                    
                    guard let currentFunctionName = currentFunctionName else { continue }
                    
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
                    
                    let nParameterFunctionData: Data = extractNParameterFunction(fromFileText: dataString)
                    
                    FileManager.default.createFile(
                        atPath: documentDirectoryPath + "YouTubeKitPlayers-\(playerName).abn",
                        contents: nParameterFunctionData
                    )
                    
                    nParameterFunction = String(decoding: nParameterFunctionData, as: UTF8.self)
                } catch {}
                break
            }
        }
        if let nParameterFunction = nParameterFunction {
            return (instructionsArray, nParameterFunction)
        } else {
            throw ResponseError(step: .scrapPlayer, reason: "Could not extract the n-parameter function.")
        }
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
    private final class DownloadPlayerOperation: Operation {
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
                    let preparedFunctionContent: [String] = line.components(separatedBy: "\(name):function(").filter({$0 != ""})
                    
                    let functionContent = preparedFunctionContent.last?.components(separatedBy: "}")[0]
                    
                    guard let functionContent = functionContent else { continue }
                    
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
    
    /// Struct representing a download format that contains the video and audio.
    public struct VideoDownloadFormat: DownloadFormat {
        public init(averageBitrate: Int? = nil, contentDuration: Int? = nil, contentLength: Int? = nil, isCopyrightedMedia: Bool? = nil, url: URL? = nil, mimeType: String? = nil, width: Int? = nil, height: Int? = nil, quality: String? = nil, fps: Int? = nil) {
            self.averageBitrate = averageBitrate
            self.contentDuration = contentDuration
            self.contentLength = contentLength
            self.isCopyrightedMedia = isCopyrightedMedia
            self.mimeType = mimeType
            self.url = url
            self.width = width
            self.height = height
            self.quality = quality
            self.fps = fps
        }
        
        /// Protocol properties
        public static let type: MediaType = .video
        
        public var averageBitrate: Int?
        
        public var contentDuration: Int?
        
        public var contentLength: Int?
        
        public var isCopyrightedMedia: Bool?
        
        public var mimeType: String?
        
        public var url: URL?
        
        /// Video-specific infos
        
        /// Width in pixels of the media.
        public var width: Int?
        
        /// Height in pixels of the media.
        public var height: Int?
        
        /// Quality label of the media
        ///
        /// For example:
        /// - **720p**
        /// - **480p**
        /// - **360p**
        public var quality: String?
        
        /// Frames per second of the media.
        public var fps: Int?
    }
    
    public struct AudioOnlyFormat: DownloadFormat {
        public init(averageBitrate: Int? = nil, contentLength: Int? = nil, contentDuration: Int? = nil, isCopyrightedMedia: Bool? = nil, url: URL? = nil, mimeType: String? = nil, audioSampleRate: Int? = nil, loudness: Double? = nil, formatLocaleInfos: FormatLocaleInfos? = nil) {
            self.averageBitrate = averageBitrate
            self.contentLength = contentLength
            self.contentDuration = contentDuration
            self.isCopyrightedMedia = isCopyrightedMedia
            self.url = url
            self.mimeType = mimeType
            self.audioSampleRate = audioSampleRate
            self.loudness = loudness
            self.formatLocaleInfos = formatLocaleInfos
        }
        
        /// Protocol properties
        public static let type: MediaType = .audio
        
        public var averageBitrate: Int?
        
        public var contentLength: Int?
        
        public var contentDuration: Int?
        
        public var isCopyrightedMedia: Bool?
        
        public var url: URL?
        
        public var mimeType: String?
        
        /// Audio only medias specific infos
        
        /// Sample rate of the audio in hertz.
        public var audioSampleRate: Int?
        
        /// Audio loudness in decibels.
        public var loudness: Double?
        
        /// Infos about the audio track language.
        ///
        /// - Note: it will be present only if the audio is not the original audio of the video.
        public var formatLocaleInfos: FormatLocaleInfos?
        
        /// Struct representing some informations about the audio track language.
        public struct FormatLocaleInfos {
            public init(displayName: String? = nil, localeId: String? = nil, isDefaultAudioFormat: Bool? = nil) {
                self.displayName = displayName
                self.localeId = localeId
                self.isDefaultAudioFormat = isDefaultAudioFormat
            }
            
            /// Name of the language, e.g. "French".
            ///
            /// - Note: the name of the language depends on the ``YouTubeModel``'s locale and the cookie's (if provided) account's default language. E.g. you would get "French" if your cookies point to an english account and "Français" if they pointed to a french one.
            public var displayName: String?
            
            /// Id of the language, generally is the language code that has ".3" has suffix. E.g. "fr.3" or "en.3".
            public var localeId: String?
            
            /// Boolean indicating whether the format is considered as the default one by YouTube (depends on the ``YouTubeModel``'s locale and the cookie's (if provided) account's default language).
            public var isDefaultAudioFormat: Bool?
        }
    }
    
    /// Decode a ``DownloadFormat`` base informations from a JSON instance.
    /// - Parameter json: the JSON to be decoded.
    /// - Returns: A ``DownloadFormat``.
    private static func decodeFromJSON(json: JSON) -> DownloadFormat {
        if json["fps"].int != nil {
            /// Will return an instance of ``VideoInfosWithDownloadFormatsResponse/VideoDownloadFormat``
            return VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat(
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
                isCopyrightedMedia: json["signatureCipher"].string != nil,
                url: nil,
                mimeType: json["mimeType"].string?.components(separatedBy: ";").first,
                width: json["width"].int,
                height: json["height"].int,
                quality: json["qualityLabel"].string,
                fps: json["fps"].int
            )
        } else {
            /// Will return an instance of ``VideoInfosWithDownloadFormatsResponse/AudioOnlyFormat``
            return VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat(
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
                url: nil,
                mimeType: json["mimeType"].string?.components(separatedBy: ";").first,
                audioSampleRate: {
                    if let audioSampleRate = json["audioSampleRate"].string {
                        return Int(audioSampleRate)
                    } else {
                        return nil
                    }
                }(),
                loudness: json["loudnessDb"].double,
                formatLocaleInfos: json["audioTrack"]["id"].string != nil ? .init(displayName: json["audioTrack"]["displayName"].string, localeId: json["audioTrack"]["id"].string, isDefaultAudioFormat: json["audioTrack"]["audioIsDefault"].bool) : nil
            )
        }
    }
    
    /// Remove all player mappings from disk.
    public static func removePlayerFilesFromDisk() throws {
        let playersDirectory = try getDocumentDirectory()
        let filesInDir = FileManager.default.enumerator(atPath: playersDirectory.absoluteString)
        guard let filesInDir = filesInDir else { return }
        for file in filesInDir {
            if let file = file as? URL {
                if file.absoluteString.hasSuffix(".ab") || file.absoluteString.hasSuffix(".abn") {
                    try FileManager.default.removeItem(at: file)
                }
            }
        }
    }
    
    /// Remove all player mappings from disk.
    public static func removePlayersFromDisk() {
        do {
            try self.removePlayerFilesFromDisk()
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
        public var step: StepType
        
        /// A string explaining the reason why the error was thrown.
        public var reason: String
        
        public enum StepType {
            case decodeData
            case processPlayerScrapping
            case scrapPlayer
            case downloadPlayer
            case getDocumentDirectory
        }
    }
}
