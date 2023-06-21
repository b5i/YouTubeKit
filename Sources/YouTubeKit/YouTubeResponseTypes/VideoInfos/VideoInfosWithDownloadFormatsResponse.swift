//
//  VideoInfosWithDownloadFormatsResponse.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 20.06.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import Foundation
import JavaScriptCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Struct representing the VideoInfosWithDownloadFormatsResponse.
///
/// For the player extraction to work properly the `sendRequest`has been "overriden" from the one precised in the protocol extension ``YouTubeResponse/sendRequest(youtubeModel:data:result:)-33bo8``.
/// The `decodeData(data)` method does not extract the player, if you wanted to use 
public struct VideoInfosWithDownloadFormatsResponse: YouTubeResponse {
    public static var headersType: HeaderTypes = .videoInfosWithDownloadFormats
    
    /// Array of formats used to download the video, usually sorted from highest video quality to lowest followed by audio formats.
    public var downloadFormats: [any DownloadFormat]
    
    /// Base video infos like if it did a ``VideoInfosResponse`` request.
    public var videoInfos: VideoInfosResponse
    
    public static func sendRequest(youtubeModel: YouTubeModel, data: [HeadersList.AddQueryInfo.ContentTypes : String], result: @escaping (VideoInfosWithDownloadFormatsResponse?, Error?) -> ()) {
        /// Get request headers.
        let headers = youtubeModel.getHeaders(forType: headersType)
        
        guard !headers.isEmpty else { result(nil, "The headers from ID: \(headersType) are empty! (probably an error in the name or they are not added in YouTubeModel.shared.customHeadersFunctions)"); return}
        
        /// Create request
        let request = HeadersList.setHeadersAgentFor(
            content: headers,
            data: data
        )
        
        /// Create task with the request
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            /// Check if the task worked and gave back data.
            if let data = data {
                ///Special processing for VideoInfosWithDownloadFormatsResponse
                
                /// The received data is not some JSON, it is an HTML file containing the JSON and other relevant informations that are necessary to process the ``DownloadFormat``.
                /// It begins by getting the player version (the player is a JS script used to manage the player on their webpage and it decodes the n-parameter).
                let dataToString = String(decoding: data, as: UTF8.self)
                
                let preparedStringForPlayerId: [String] = dataToString.components(separatedBy: "<link rel=\"preload\" href=\"https://i.ytimg.com/generate_204\" as=\"fetch\"><link as=\"script\" rel=\"preload\" href=\"")
                
                guard preparedStringForPlayerId.count > 1 else { result(VideoInfosWithDownloadFormatsResponse(downloadFormats: [], videoInfos: .createEmpty()), error); return }
                
                /// We have something like this **/s/player/playerId/player_ias.vflset/en_US/base.js**
                let playerPath: String = preparedStringForPlayerId[1].components(separatedBy: "\" nonce=\"")[0]
                
                processPlayerScrapping(playerPath: playerPath) { instructionArray, nParameter in
                    /// Time to exctract the real JSON from the HTML
                    var preparedStringForJSONData: [String] = dataToString.components(separatedBy: "var ytInitialPlayerResponse = ")
                    
                    guard preparedStringForJSONData.count > 1 else { result( VideoInfosWithDownloadFormatsResponse(downloadFormats: [], videoInfos: .createEmpty()), nil); return }
                    
                    preparedStringForJSONData = preparedStringForJSONData[1].components(separatedBy: ";</script><div id=\"player\"")
                    
                    let stringJSONData = preparedStringForJSONData[0]
                    
                    let json = JSON(stringJSONData.data(using: .utf8) ?? Data())
                    
                    guard let downloadFormatsJSONArray = json["streamingData"]["adaptiveFormats"].array else { result(VideoInfosWithDownloadFormatsResponse(downloadFormats: [], videoInfos: .createEmpty()), nil); return }
                    
                    let downloadFormats: [DownloadFormat] = convertJSONToDownloadFormats(
                        json: downloadFormatsJSONArray,
                        playerPath: playerPath,
                        instructionsArray: instructionArray,
                        nParameterString: nParameter
                    )
                    result(
                        VideoInfosWithDownloadFormatsResponse(
                            downloadFormats: downloadFormats,
                            videoInfos: VideoInfosResponse.decodeJSON(json)
                        ),
                        error
                    )
                }
            } else {
                /// Exectued if the data was nil so there was probably an error.
                result(nil, error)
            }
        }
        
        /// Start it
        task.resume()
    }
    
    public static func decodeData(data: Data) -> VideoInfosWithDownloadFormatsResponse {
        /// The received data is not some JSON, it is an HTML file containing the JSON and other relevant informations that are necessary to process the ``DownloadFormat``.
        /// It begins by getting the player version (the player is a JS script used to manage the player on their webpage and it decodes the n-parameter).
        let dataToString = String(decoding: data, as: UTF8.self)
        
        let preparedStringForPlayerId: [String] = dataToString.components(separatedBy: "<link rel=\"preload\" href=\"https://i.ytimg.com/generate_204\" as=\"fetch\"><link as=\"script\" rel=\"preload\" href=\"")
        
        guard preparedStringForPlayerId.count > 1 else { return VideoInfosWithDownloadFormatsResponse(downloadFormats: [], videoInfos: .createEmpty()) }
        
        /// We have something like this **/s/player/playerId/player_ias.vflset/en_US/base.js**
        let playerPath: String = preparedStringForPlayerId[1].components(separatedBy: "\" nonce=\"")[0]
                    
        /// Time to exctract the real JSON from the HTML
        var preparedStringForJSONData: [String] = dataToString.components(separatedBy: "var ytInitialPlayerResponse = ")
        
        guard preparedStringForJSONData.count > 1 else { return VideoInfosWithDownloadFormatsResponse(downloadFormats: [], videoInfos: .createEmpty()) }
        
        preparedStringForJSONData = preparedStringForJSONData[1].components(separatedBy: ";</script><div id=\"player\"")
        
        let stringJSONData = preparedStringForJSONData[0]
        
        let json = JSON(stringJSONData)
        
        guard let downloadFormatsJSONArray = json["streamingData"]["adaptiveFormats"].array else { return VideoInfosWithDownloadFormatsResponse(downloadFormats: [], videoInfos: .createEmpty()) }
        
        let downloadFormats: [DownloadFormat] = convertJSONToDownloadFormats(json: downloadFormatsJSONArray, playerPath: playerPath)
        
        return VideoInfosWithDownloadFormatsResponse(
            downloadFormats: downloadFormats,
            videoInfos: VideoInfosResponse.decodeJSON(json)
        )
    }
    
    /// Get an array of ``DownloadFormat`` from a JSON array.
    /// - Parameters:
    ///   - json: the JSON that has to be decoded.
    ///   - playerPath: the path of the player in YouTube's website (without the youtube.com at the beginning)
    ///   - instructionsArray: an array of ``PlayerCipherDecodeInstruction`` that can be precised to avoid reading the encoded file on disk.
    ///   - nParameterString: a string representing the Javascript code of the nParameter function that can be precised to avoid reading the encoded file on disk.
    /// - Returns: an array of ``DownloadFormat``.
    private static func convertJSONToDownloadFormats(
        json: [JSON],
        playerPath: String,
        instructionsArray: [PlayerCipherDecodeInstruction]? = nil,
        nParameterString: String? = nil
    ) -> [DownloadFormat] {
        var preparedStringForPlayerName: [String] = playerPath.components(separatedBy: "s/player/")
        
        guard preparedStringForPlayerName.count > 1 else { return [] }
        
        preparedStringForPlayerName = preparedStringForPlayerName[1].components(separatedBy: "/")
        
        let playerName = preparedStringForPlayerName[0]
        //verify if path is / ok
        do {
            let playerSavedInstruction: [PlayerCipherDecodeInstruction]
            if let instructionsArray = instructionsArray {
                /// Instruction in memory have been provided
                playerSavedInstruction = instructionsArray
            } else {
                /// Search in files
                let playerPathInDocuments = getDocumentDirectory().absoluteString + "YouTubeKitPlayers-\(playerName).ab"
                let playerURLInDocuments = URL(string: playerPathInDocuments)
                guard let playerURLInDocuments = playerURLInDocuments else { return [] }
                let playerSavedContent: Data = try Data(contentsOf: playerURLInDocuments)
                
                playerSavedInstruction = try JSONDecoder().decode([PlayerCipherDecodeInstruction].self, from: playerSavedContent)
            }
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
                                        
                    for instruction in playerSavedInstruction {
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
                
                guard let urlComponents = URLComponents(string: item.url?.absoluteString ?? "") else { return item }
                
                var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
                
                let nParameter = queryItems.first(where: {$0.name == "n"})?.value
                queryItems.removeAll(where: {$0.name == "n"})
                
                guard let nParameter = nParameter else { return item }
                
                //verify if path is / ok
                do {
                    let nParameterFunction: String
                    if let nParameterString = nParameterString {
                        /// NParameterFunction in memory have been provided
                        nParameterFunction = nParameterString
                    } else {
                        /// Search in files
                        let nParameterPathInDocuments = getDocumentDirectory().absoluteString + "YouTubeKitPlayers-\(playerName).abn"
                        guard let nParameterURLInDocuments = URL(string: nParameterPathInDocuments) else { return item }
                        nParameterFunction = try String(contentsOf: nParameterURLInDocuments, encoding: .utf8)
                    }
                    let context = JSContext()
                    
                    guard let context = context else { return item }
                    
                    context.evaluateScript(nParameterFunction)

                    let testFunction = context.objectForKeyedSubscript("processNParameter")
                    let result = testFunction?.call(withArguments: [nParameter])
                                        
                    guard let result = result, result.isString, let result = result.toString() else { return item }
                    
                    item.url?.append(queryItems: [
                        URLQueryItem(name: "n", value: result)
                    ])
                } catch {}
                return item
            })
        } catch {
            return []
        }
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
    ///  - done: a closure potentially containing an array of ``PlayerCipherDecodeInstruction`` and a string representing the nParameter function in Javascript code.
    private static func processPlayerScrapping(
        playerPath: String,
        done: @escaping ([PlayerCipherDecodeInstruction]?, String?) -> ()
    ) {
        guard let playerURL = URL(string: "https://youtube.com\(playerPath)") else { return }
        var preparedStringForPlayerName: [String] = playerPath.components(separatedBy: "s/player/")
        
        guard preparedStringForPlayerName.count > 1 else { return }
        
        preparedStringForPlayerName = preparedStringForPlayerName[1].components(separatedBy: "/")
        
        let playerName = preparedStringForPlayerName[0]
                
        if !FileManager.default.fileExists(atPath: getDocumentDirectory().absoluteString + "YouTubeKitPlayers-\(playerName).ab") {
            scrapPlayer(playerName: playerName, playerURL: playerURL) { instructionsArray, nParameterFunction in
                done(instructionsArray, nParameterFunction)
            }
        } else {
            done(nil, nil)
        }
    }
    
    /// Scrap functions from the player
    /// - Parameters:
    ///   - playerName: the player's name.
    ///   - playerURL: player's URL (should point to YouTube's website)
    ///   - done: a closure potentially containing an array of ``PlayerCipherDecodeInstruction`` and a string representing the nParameter function in Javascript code.
    private static func scrapPlayer(
        playerName: String,
        playerURL: URL,
        done: @escaping ([PlayerCipherDecodeInstruction]?, String?) -> ()
    ) {
        downloadPlayer(playerURL: playerURL) { data, error in
            guard error == nil, let data = data else {
                done(nil, nil)
                return
            }
            let dataString = String(decoding: data, as: UTF8.self)
            /// Separate the data by line.
            let separatedByLinePlayer: [String] = dataString.components(separatedBy: .newlines)
            
            /// Dictionnary containing the names of the PlayerCipherDecodeInstruction in the player's code and link them with their corresponding PlayerCipherDecodeInstruction.
            var knownPlayerCipherDecodeInstructions: [String : PlayerCipherDecodeInstruction] = [:]
            
            var instructionsArray: [PlayerCipherDecodeInstruction] = []
            
            var nParameterFunction: String? = nil
            
            for line in separatedByLinePlayer {
                if line.contains("a=a.split(\"\");") {
                    let functionArray: [String] = line.components(separatedBy: "=function(a){a=a.split(\"\");")
                    
                    guard functionArray.count > 1 else { return }
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
                    do {
                        FileManager.default.createFile(
                            atPath: getDocumentDirectory().absoluteString + "YouTubeKitPlayers-\(playerName).ab",
                            contents: try JSONEncoder().encode(instructionsArray)
                        )
                        
                        let nParameterFunctionData: Data = extractNParameterFunction(fromFileText: dataString)
                        
                        FileManager.default.createFile(
                            atPath: getDocumentDirectory().absoluteString + "YouTubeKitPlayers-\(playerName).abn",
                            contents: nParameterFunctionData
                        )
                        
                        nParameterFunction = String(decoding: nParameterFunctionData, as: UTF8.self)
                    } catch {}
                    break
                }
            }
            done(instructionsArray, nParameterFunction)
        }
    }
    
    /// Download the player with its URL.
    /// - Parameters:
    ///   - playerURL: URL of the player
    ///   - result: returns either Data or Error depending on the download success.
    private static func downloadPlayer(
        playerURL: URL,
        result: @escaping (Data?, Error?) -> ()
    ) {
        let task = URLSession.shared.dataTask(with: playerURL, completionHandler: { data, _, error in
            result(data, error)
        })
        task.resume()
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
        /// Protocol properties
        public static let type: MediaType = .video
        
        public var averageBitrate: Int?
        
        public var contentDuration: Int?
        
        public var contentLength: Int?
        
        public var isCopyrightedMedia: Bool?
        
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
        /// Protocol properties
        public static let type: MediaType = .audio
        
        public var averageBitrate: Int?
        
        public var contentLength: Int?
        
        public var contentDuration: Int?
        
        public var isCopyrightedMedia: Bool?
        
        public var url: URL?
        
        /// Audio only medias specific infos
        
        /// Sample rate of the audio in hertz.
        public var audioSampleRate: Int?
        
        /// Audio loudness in decibels.
        public var loudness: Double?
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
                audioSampleRate: {
                    if let audioSampleRate = json["audioSampleRate"].string {
                        return Int(audioSampleRate)
                    } else {
                        return nil
                    }
                }(),
                loudness: json["loudnessDb"].double
            )
        }
    }
    
    /// Remove all player mappings from disk.
    public static func removePlayersFromDisk() {
        let playersDirectory = getDocumentDirectory()
        let filesInDir = FileManager.default.enumerator(atPath: playersDirectory.absoluteString)
        guard let filesInDir = filesInDir else { return }
        for file in filesInDir {
            if let file = file as? URL {
                if file.absoluteString.hasSuffix(".ab") || file.absoluteString.hasSuffix(".abn") {
                    do {
                        try FileManager.default.removeItem(at: file)
                    } catch {}
                }
            }
        }
    }
    
    /// Get the document directory from the project that is using ``YouTubeKit``
    /// - Returns: The URL of this document directory.
    private static func getDocumentDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
