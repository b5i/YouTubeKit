import XCTest
@testable import YouTubeKit

final class YouTubeKitTests: XCTestCase {
    private let YTM = YouTubeModel()
    
    /// Keep them secret! Make sure you remove them after having tested YouTubeKit. If they're let empty, the requests requiring authentification will pass but won't be tested.
    private let cookies = ""
    
    func testCreateCustomHeaders() async throws {
        let TEST_NAME = "Test: testCreateCustomHeaders() -> "
        let myCustomHeadersFunction: () -> HeadersList = {
            HeadersList(
                url: URL(string: "https://raw.githubusercontent.com/b5i/antoinebollengier/main/YouTubeKitTests/CreateCustomHeadersGET.json")!,
                method: .GET,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Accept-Language", content: "\(self.YTM.selectedLocale);q=0.9"),
                ]
            )
        }
        
        YTM.customHeadersFunctions["nameAndSurname"] = myCustomHeadersFunction
        
        /// Struct representing a getNameAndSurname response.
        struct NameAndSurnameResponse: YouTubeResponse {
            static var headersType: HeaderTypes = .customHeaders("nameAndSurname")
            
            static var parametersValidationList: ValidationList = [:]
            
            /// String representing a name.
            var name: String = ""
            
            /// String representing a surname.
            var surname: String = ""
            
            static func decodeJSON(json: JSON) -> NameAndSurnameResponse {
                /// Initialize an empty response.
                var nameAndSurnameResponse = NameAndSurnameResponse()
                
                nameAndSurnameResponse.name = json["name"].stringValue
                nameAndSurnameResponse.surname = json["surname"].stringValue
                
                return nameAndSurnameResponse
            }
        }
        
        let NAME_SHOULD_BE = "myName"
        let SURNAME_SHOULD_BE = "mySurname"
        
        let response = try await NameAndSurnameResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
        
        if response.name == NAME_SHOULD_BE && response.surname == SURNAME_SHOULD_BE {
            XCTAssert(true, TEST_NAME + "successful!")
        } else {
            XCTFail(TEST_NAME + "the name != \(NAME_SHOULD_BE) actually (\(response.name)) or surname != \(SURNAME_SHOULD_BE) actually (\(response.surname))")
        }
    }
    
    func testLogger() async throws {
        let TEST_NAME = "Test: testLogger() -> "
        final class Logger: RequestsLogger, @unchecked Sendable { // TODO: Find a way, respecting Swift Concurrency, to have a proper Sendable Logger that also conforms to RequestLogger. (might need to modify RequestLogger for that)
            let queue = DispatchQueue(label: "YTK_TESTS_LOGGER")
            
            var loggedTypes: [any YouTubeResponse.Type]? = nil
            
            var maximumCacheSize: Int? = nil
            
            var logs: [any GenericRequestLog] = []
            
            var isLogging: Bool = false
            
            func startLogging() {
                self.queue.sync {
                    self.isLogging = true
                }
            }
            
            func stopLogging() {
                self.queue.sync {
                    self.isLogging = false
                }
            }
            
            
            func setCacheSize(_ size: Int?) {
                self.queue.sync {
                    self.maximumCacheSize = size
                    if let size = size {
                        self.removeFirstLogsWith(limit: size)
                    }
                }
            }
            
            
            func addLog(_ log: any GenericRequestLog) {
                @Sendable func compareTypes<T: GenericRequestLog, U: YouTubeResponse>(log1: T, log2: U.Type) -> Bool {
                    let newRequest: RequestLog<U>
                    return type(of: log1) == type(of: newRequest)
                }
                
                self.queue.sync {
                    guard self.isLogging, (self.maximumCacheSize ?? 1) > 0 else { return }
                    guard (self.loggedTypes?.contains(where: { compareTypes(log1: log, log2: $0) }) ?? true) else { return }
                    if let maximumCacheSize = self.maximumCacheSize {
                        self.removeFirstLogsWith(limit: max(maximumCacheSize - 1, 0))
                    }
                    self.logs.append(log)
                }
            }
            
            
            func clearLogs() {
                self.queue.sync {
                    self.logs.removeAll()
                }
            }
            
            func clearLogsWithIds(_ ids: [UUID]) {
                self.queue.sync {
                    for idToRemove in ids {
                        self.logs.removeAll(where: {$0.id == idToRemove})
                    }
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
        
        let logger = Logger()
        
        YTM.logger = logger
        
        struct ModulableResponse: YouTubeResponse {
            static var headersType: YouTubeKit.HeaderTypes = .home // random headers, the request's data won't be checked.
            
            static var parametersValidationList: ValidationList = [.browseId: .existenceValidator]
            
            static func decodeData(data: Data) throws -> ModulableResponse { return ModulableResponse() }
            
            static func decodeJSON(json: JSON) -> ModulableResponse { return ModulableResponse() }
        }
        
        let result1 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [:]) // should be nil as `browseId` has not been set
        XCTAssertNil(result1, TEST_NAME + "result1 should be nil")
        XCTAssertEqual(logger.logs.count, 0, TEST_NAME + "the logger shouldn't have any result in it")
        
        logger.startLogging()
        
        let result2 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [.browseId: ""]) // shouldn't be nil as `browseId` is set
        XCTAssertNotNil(result2, TEST_NAME + "result2 should not be nil")
        XCTAssertEqual(logger.logs.count, 1, TEST_NAME + "the logger should only have result2 in it")
        
        let result3 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [:]) // should be nil as `browseId` has not been set
        XCTAssertNil(result3, TEST_NAME + "result3 should be nil")
        XCTAssertEqual(logger.logs.count, 2, TEST_NAME + "the logger should contain exactly 2 logs")
        
        let result4 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [:]) // should be nil as `browseId` has not been set
        XCTAssertNil(result4, TEST_NAME + "result4 should be nil")
        XCTAssertEqual(logger.logs.count, 3, TEST_NAME + "the logger should contain exactly 3 logs")
        
        let result5 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [:]) // should be nil as `browseId` has not been set
        XCTAssertNil(result5, TEST_NAME + "result5 should be nil")
        XCTAssertEqual(logger.logs.count, 4, TEST_NAME + "the logger should contain exactly 4 logs")
        
        logger.setCacheSize(4)
        
        let result6 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [:]) // should be nil as `browseId` has not been set
        XCTAssertNil(result6, TEST_NAME + "result5 should be nil")
        XCTAssertEqual(logger.logs.count, 4, TEST_NAME + "the logger should contain exactly 4 logs")
        
        logger.setCacheSize(nil)
        
        let result7 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [:]) // should be nil as `browseId` has not been set
        XCTAssertNil(result7, TEST_NAME + "result7 should be nil")
        XCTAssertEqual(logger.logs.count, 5, TEST_NAME + "the logger should contain exactly 5 logs")
        
        logger.stopLogging()
        
        let result8 = try? await ModulableResponse.sendThrowingRequest(youtubeModel: YTM, data: [.browseId: ""]) // shouldn't be nil as `browseId` is set
        XCTAssertNotNil(result8, TEST_NAME + "result8 should not be nil")
        XCTAssertEqual(logger.logs.count, 5, TEST_NAME + "the logger should contain exactly 5 logs")
        
        logger.clearLogWithId(logger.logs.first!.id) // count is 4 so the first element should exist
        XCTAssertEqual(logger.logs.count, 4, TEST_NAME + "the logger should contain only 4 logs after deleting the first one")
        
        logger.clearLogsWithIds([logger.logs[0].id, logger.logs[1].id])
        XCTAssertEqual(logger.logs.count, 2, TEST_NAME + "the logger should contain only 2 log after deleting the 2 first")
        
        logger.clearLogs()
        XCTAssertEqual(logger.logs.count, 0, TEST_NAME + "the logger shouldn't contain any log after clearing all of them")
        
        logger.startLogging()
        
        let _ = try await HomeScreenResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
        XCTAssertEqual(logger.logs.count, 1, TEST_NAME + "the logger should contain 1 log")
        
        logger.loggedTypes = [SearchResponse.self] // so not the HomeScreenResponse and it shouldn't be logged
        
        let _ = try await HomeScreenResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
        XCTAssertEqual(logger.logs.count, 1, TEST_NAME + "the logger should contain 1 log")
        
        logger.loggedTypes = [HomeScreenResponse.self]
        
        let _ = try await HomeScreenResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
        XCTAssertEqual(logger.logs.count, 2, TEST_NAME + "the logger should contain 2 log")
        
        YTM.logger = nil
    }
    
    func testDefaultValidators() throws {
        let TEST_NAME = "Test: testHeadersToRequest() -> "
        
        func testVideoIdValidator() {
            // an array of potential video ids and a boolean indicating if they should pass the validator's test or not

            let videoIdsAndValidity: [(String?, Bool)] = [
                (nil, false), ("", false), ("dfnidf", false),
                ("3ryID_SwU5E", true), ("peIBCNTY8hA", true),
                ("OlWdMCVtKJw", true), ("OlWdMCVtKJwe3r3r", false)
            ]
            
            for (videoId, expectedResult) in videoIdsAndValidity {
                do {
                    _ = try ParameterValidator.videoIdValidator.validate(parameter: videoId, contentType: .browseId)
                    if !expectedResult {
                        XCTFail(TEST_NAME + "videoId: \(String(describing: videoId)) should be invalid but passed.")
                    }
                } catch {
                    if expectedResult {
                        XCTFail(TEST_NAME + "videoId: \(String(describing: videoId)) should be valid but failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        func testOptionalVideoIdValidator() {
            // an array of potential video ids and a boolean indicating if they should pass the validator's test or not

            let videoIdsAndValidity: [(String?, Bool)] = [
                ("3ryID_SwU5E", true), (nil, true), ("OlWdMCVtKJwe3r3r", false)
            ]
            
            for (videoId, expectedResult) in videoIdsAndValidity {
                do {
                    _ = try ParameterValidator.optionalVideoIdValidator.validate(parameter: videoId, contentType: .browseId)
                    if !expectedResult {
                        XCTFail(TEST_NAME + "videoId: \(String(describing: videoId)) should be invalid but passed.")
                    }
                } catch {
                    if expectedResult {
                        XCTFail(TEST_NAME + "videoId: \(String(describing: videoId)) should be valid but failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        func testChannelIdValidator() {
            // an array of potential channel ids and a boolean indicating if they should pass the validator's test or not

            let channelIdsAndValidity: [(String?, Bool)] = [
                (nil, false), ("", false), ("dfnidf", false),
                ("UCX6OQ3DkcsbYNE6H8uQQuVA", true),
                ("peIBCNTY8hA", false),
                ("UCX6OQ3DkcsbYNE6H8uQQuVAgrigrnirginr", false)
            ]
            
            for (channelId, expectedResult) in channelIdsAndValidity {
                do {
                    _ = try ParameterValidator.channelIdValidator.validate(parameter: channelId, contentType: .browseId)
                    if !expectedResult {
                        XCTFail(TEST_NAME + "channelId: \(String(describing: channelId)) should be invalid but passed.")
                    }
                } catch {
                    if expectedResult {
                        XCTFail(TEST_NAME + "channelId: \(String(describing: channelId)) should be valid but failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        func testPlaylistIdWithVLValidator() {
            do {
                let result = try ParameterValidator.playlistIdWithVLPrefixValidator.validate(parameter: "...", contentType: .browseId)
                if result?.hasPrefix("VL") == false {
                    XCTFail(TEST_NAME + "Playlist id not starting with VL should have been normalized but got: \(String(describing: result))")
                }
            } catch { /* expected for invalids handled by validate */ }
            
            do {
                _ = try ParameterValidator.playlistIdWithVLPrefixValidator.validate(parameter: "VL...", contentType: .browseId)
            } catch {
                XCTFail(TEST_NAME + "Playlist id starting with VL should pass but failed: \(error.localizedDescription)")
            }
        }
        
        func testPlaylistIdWithoutVLValidator() {
            do {
                let result = try ParameterValidator.playlistIdWithoutVLPrefixValidator.validate(parameter: "VL...", contentType: .browseId)
                if result?.hasPrefix("VL") == true {
                    XCTFail(TEST_NAME + "Playlist id starting with VL shouldn't retain prefix but got: \(String(describing: result))")
                }
            } catch { /* expected failure */ }
            
            do {
                _ = try ParameterValidator.playlistIdWithoutVLPrefixValidator.validate(parameter: "...", contentType: .browseId)
            } catch {
                XCTFail(TEST_NAME + "Playlist id not starting with VL should pass but failed: \(error.localizedDescription)")
            }
        }
        
        func testPrivacyValidator() {
            for privacy in YTPrivacy.allCases.compactMap({ $0.rawValue }) {
                do {
                    _ = try ParameterValidator.privacyValidator.validate(parameter: privacy, contentType: .browseId)
                } catch {
                    XCTFail(TEST_NAME + "Base privacy type: \(privacy) should pass but failed: \(error.localizedDescription)")
                }
            }
            
            do {
                _ = try ParameterValidator.privacyValidator.validate(parameter: "Definitely not a valid privacy type", contentType: .browseId)
                XCTFail(TEST_NAME + "Invalid privacy should fail but passed.")
            } catch { /* expected */ }
        }
        
        func testURLValidator() {
            let testAndResult: [(String?, Bool)] = [
                ("https://google.com", true),
                ("google.com", true),
                ("www.google.com", true),
                ("www.google.com/test?param=test&param2=test2", true),
                ("google", true), // it's obviously not a valid URL but it can be converted to URL in swift
                (nil, false)
            ]
            
            for (test, shouldPass) in testAndResult {
                do {
                    _ = try ParameterValidator.urlValidator.validate(parameter: test, contentType: .browseId)
                    if !shouldPass {
                        XCTFail(TEST_NAME + "Invalid URL \(String(describing: test)) should fail but passed.")
                    }
                } catch {
                    if shouldPass {
                        XCTFail(TEST_NAME + "Valid URL \(String(describing: test)) failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        func testExistenceValidator() {
            do {
                _ = try ParameterValidator.existenceValidator.validate(parameter: nil, contentType: .browseId)
                XCTFail(TEST_NAME + "nil should not pass the existence validator.")
            } catch { /* expected */ }
            
            do {
                _ = try ParameterValidator.existenceValidator.validate(parameter: "non-nil string", contentType: .browseId)
            } catch {
                XCTFail(TEST_NAME + "non-nil string should pass existence validator: \(error.localizedDescription)")
            }
        }
                
        testVideoIdValidator()
        testOptionalVideoIdValidator()
        testChannelIdValidator()
        testPlaylistIdWithVLValidator()
        testPlaylistIdWithoutVLValidator()
        testPrivacyValidator()
        testExistenceValidator()
        testURLValidator()
    }
    
    func testHeadersToRequest() async {
        let TEST_NAME = "Test: testHeadersToRequest() -> "
        
        /// Testing body creation
        for item in HeadersList.AddQueryInfo.ContentTypes.allCases.filter({$0 != .query}) {
            let myCustomHeadersFunction: () -> HeadersList = {
                HeadersList(
                    url: URL(string: "https://raw.githubusercontent.com/b5i/antoinebollengier/main/YouTubeKitTests/CreateCustomHeadersGET.json")!,
                    method: .POST,
                    headers: [
                        .init(name: "Accept", content: "*/*"),
                        .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                        .init(name: "Accept-Language", content: "\(self.YTM.selectedLocale);q=0.9"),
                    ],
                    addQueryAfterParts: [
                        .init(index: 0, encode: true, content: item),
                        .init(index: 1, encode: false, content: item),
                        .init(index: 2, encode: true),
                        .init(index: 3, encode: false)
                    ],
                    httpBody: [
                        "encodedItem:",
                        "nonEncodedItem:",
                        "encodedQuery:",
                        "nonEncodedQuery:"
                    ]
                )
            }
            
            var data: [HeadersList.AddQueryInfo.ContentTypes : String] = [.query : "query@/"]
            if item != .query {
                data[item] = "\(item.rawValue)@/"
            }
            
            let request = HeadersList.setHeadersAgentFor(
                content: myCustomHeadersFunction(),
                data: data
            )
            
            guard let wrappedBody = request.httpBody else { XCTFail(TEST_NAME + "request.httpBody is nil"); return }
            
            let decodedBody = String(decoding: wrappedBody, as: UTF8.self)
            let decodedBodyShouldBe = "encodedItem:\(item.rawValue)%40%2FnonEncodedItem:\(item.rawValue)@/encodedQuery:query%40%2FnonEncodedQuery:query@/"
            XCTAssertEqual(decodedBody, decodedBodyShouldBe, TEST_NAME + "Checking equality of bodies.")
        }
        
        /// Testing URL parameters
        
        let myCustomHeadersFunction: () -> HeadersList = {
            HeadersList(
                url: URL(string: "https://raw.githubusercontent.com/b5i/antoinebollengier/main/YouTubeKitTests/CreateCustomHeadersGET.json")!,
                method: .GET,
                headers: [
                    .init(name: "Accept", content: "*/*"),
                    .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                    .init(name: "Accept-Language", content: "\(self.YTM.selectedLocale);q=0.9"),
                    .init(name: "MyCustomHTTPHeader", content: "Ahahahah")
                ],
                parameters: [
                    .init(name: "q", content: "testquery/@"),
                    .init(name: "t", content: "", specialContent: .query)
                ]
            )
        }
        
        let data: [HeadersList.AddQueryInfo.ContentTypes : String] = [.query : "query@/"]
        
        let request = HeadersList.setHeadersAgentFor(
            content: myCustomHeadersFunction(),
            data: data
        )
        
        guard let wrappedURL = request.url else { XCTFail(TEST_NAME + "request.url is nil"); return }
        
        let decodedURL = wrappedURL.absoluteString
        let decodedURLShouldBe = "https://raw.githubusercontent.com/b5i/antoinebollengier/main/YouTubeKitTests/CreateCustomHeadersGET.json?q=testquery/@&t=query@/"
        XCTAssertEqual(decodedURL, decodedURLShouldBe, TEST_NAME + "Checking equality of URLs.")
        
        /// Checking actual headers
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "*/*", TEST_NAME + "Checking equality of header \"Accept\".")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Encoding"), "gzip, deflate, br", TEST_NAME + "Checking equality of header \"Accept-Encoding\".")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "\(self.YTM.selectedLocale);q=0.9", TEST_NAME + "Checking equality of header \"Accept-Language\".")
        XCTAssertEqual(request.value(forHTTPHeaderField: "MyCustomHTTPHeader"), "Ahahahah", TEST_NAME + "Checking equality of header \"MyCustomHTTPHeader\".")
    }
    
    func testRestrictedSearch() async throws {
        let TEST_NAME = "Test: testRestrictedSearch() -> "
        
        let requestResult = try await SearchResponse.Restricted.sendThrowingRequest(youtubeModel: YTM, data: [.query: "mrbeast"])
                
        XCTAssertNotEqual(requestResult.results.count, 0, TEST_NAME + "Checking if there is actual results in requestResult.results")
    }

    func testSearchResponseContinuation() async throws {
        let TEST_NAME = "Test: testSearchResponseContinuation() -> "
        
        var searchResult = try await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "Zen Emission"])
        
        // Zen Emission has special channel json containing the video count of his channel
        
        if let firstChannel = searchResult.results.first(where: {$0 as? YTChannel != nil}) as? YTChannel {
            XCTAssertNotNil(firstChannel.name)
            XCTAssertNotNil(firstChannel.subscriberCount)
            XCTAssertNotNil(firstChannel.videoCount)
            XCTAssertNotEqual(firstChannel.thumbnails.count, 0)
        }
        
        searchResult = try await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "mrbeast"])
        
        if let firstChannel = searchResult.results.first(where: {$0 as? YTChannel != nil}) as? YTChannel {
            XCTAssertNotNil(firstChannel.name)
            XCTAssertNotNil(firstChannel.handle)
            XCTAssertNotNil(firstChannel.subscriberCount)
            XCTAssertNotEqual(firstChannel.thumbnails.count, 0)
        }
        
        if let firstVideo = searchResult.results.first(where: {$0 as? YTVideo != nil}) as? YTVideo {
            XCTAssertNotNil(firstVideo.title)
            XCTAssertNotNil(firstVideo.channel)
            XCTAssertNotNil(firstVideo.thumbnails)
            XCTAssertNotNil(firstVideo.timeLength)
            XCTAssertNotNil(firstVideo.viewCount)
            XCTAssertNotNil(firstVideo.timePosted)
            XCTAssertNotNil(firstVideo.channel?.name)
            XCTAssertNotEqual(firstVideo.channel?.thumbnails.count, 0)
        }
        
        if let firstPlaylist = searchResult.results.first(where: {$0 as? YTPlaylist != nil}) as? YTPlaylist {
            XCTAssertNotNil(firstPlaylist.title)
            XCTAssertNotNil(firstPlaylist.channel)
            XCTAssertNotEqual(firstPlaylist.thumbnails.count, 0)
            XCTAssertNotNil(firstPlaylist.videoCount)
            XCTAssertNotNil(firstPlaylist.privacy)
            XCTAssertNotNil(firstPlaylist.timePosted)
            XCTAssertNotEqual(firstPlaylist.frontVideos.count, 0)
        }
        
        guard let continuationToken = searchResult.continuationToken else { XCTFail(TEST_NAME + "continuationToken is not defined"); return }
        guard let visitorData = searchResult.visitorData else { XCTFail(TEST_NAME + "visitorData is not defined"); return }
        let continuationResult = try await SearchResponse.Continuation.sendThrowingRequest(youtubeModel: YTM, data: [
            .continuation: continuationToken,
            .visitorData: visitorData
        ])
                
        XCTAssertNotEqual(continuationResult.continuationToken, "", TEST_NAME + "Checking continuationToken for SearchResponse.Contination.")
        XCTAssertNotEqual(continuationResult.results.count, 0, TEST_NAME + "Checking if continuation results aren't empty.")
        
        let expectedFinalVideosCount = searchResult.results.count + continuationResult.results.count
        
        searchResult.mergeContinuation(continuationResult)
        XCTAssertEqual(searchResult.results.count, expectedFinalVideosCount, TEST_NAME + "Checking the number of videos of the searchResult after merging the continuation.")
        XCTAssertEqual(searchResult.continuationToken, continuationResult.continuationToken, TEST_NAME + "Checking if the continuationToken of the continuationResult has overriden the old one from searchResult in searchResult.")
    }
    
    func testVideoInfosResponse() async throws {
        let TEST_NAME = "Test: testVideoInfosResponse() -> "
        let video = YTVideo(videoId: "90RLzVUuXe4")
                
        if YTM.visitorData == "" {
            guard let visitorData = try await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "home"]).visitorData else { XCTFail("VisitorData is not present in SearchResponse."); return }
            YTM.visitorData = visitorData
        }
        
        let requestResult = try await video.fetchStreamingInfosThrowing(youtubeModel: YTM)
        
        XCTAssert(!requestResult.captions.isEmpty, TEST_NAME + "Checking if requestResult.captions is not nil.")
        
        XCTAssertNotNil(requestResult.channel?.name, TEST_NAME + "Checking if requestResult.channel.name is not nil.")
        XCTAssertNotNil(requestResult.channel?.channelId, TEST_NAME + "Checking if requestResult.channel.browseId is not nil.")
        XCTAssertNotNil(requestResult.isLive, TEST_NAME + "Checking if requestResult.isLive is not nil.")
        XCTAssertNotEqual(requestResult.keywords.count, 0, TEST_NAME + "Checking if requestResult.channel.name is not nil.")
        XCTAssertNotNil(requestResult.streamingURL, TEST_NAME + "Checking if requestResult.streamingURL is not nil.")
        XCTAssertNotNil(requestResult.title, TEST_NAME + "Checking if requestResult.title is not nil.")
        XCTAssertNotNil(requestResult.videoDescription, TEST_NAME + "Checking if requestResult.videoDescription is not nil.")
        XCTAssertNotNil(requestResult.videoId, TEST_NAME + "Checking if requestResult.videoId is not nil.")
        XCTAssertNotNil(requestResult.videoURLsExpireAt, TEST_NAME + "Checking if requestResult.videoURLsExpireAt is not nil.")
        XCTAssertNotNil(requestResult.viewCount, TEST_NAME + "Checking if requestResult.viewCount is not nil.")
        XCTAssertNotNil(requestResult.aspectRatio, TEST_NAME + "Checking if requestResult.aspectRatio is not nil.")
        //XCTAssertNotEqual(requestResult.downloadFormats.count, 0, TEST_NAME + "Checking if requestResult.downloadFormats is empty")
        //XCTAssertNotEqual(requestResult.defaultFormats.count, 0, TEST_NAME + "Checking if requestResult.defaultFormats is empty")
        
        let captionsResults = try await VideoCaptionsResponse.sendThrowingRequest(youtubeModel: YTM, data: [.customURL: requestResult.captions.first!.url.absoluteString])
        
        XCTAssert(!captionsResults.captionParts.isEmpty, TEST_NAME + "Checking if captionsResults.captionParts is not empty")
        
        let testCaptionsResponse = VideoCaptionsResponse(captionParts: [
            .init(text: "[Music]", startTime: 13.119999999999999, duration: 3.0800000000000001),
            .init(text: "i'm good yeah i'm feeling all right baby", startTime: 16.559999999999999, duration: 3.2800000000000011),
            .init(text: "i'mma have the best night of my", startTime: 19.84, duration: 2.5599999999999987),
            .init(text: "life and wherever it takes me i'm down", startTime: 22.399999999999999, duration: 3.2800000000000011),
            .init(text: "for the ride baby don't you know i'm", startTime: 25.68, duration: 2.6400000000000006)
        ])
        
        XCTAssertEqual(
            testCaptionsResponse.getFormattedString(withFormat: .vtt),
        """
        WEBVTT
        
        1
        00:00:13.119 --> 00:00:16.199
        [Music]
        
        2
        00:00:16.559 --> 00:00:19.839
        i\'m good yeah i\'m feeling all right baby
        
        3
        00:00:19.839 --> 00:00:22.399
        i\'mma have the best night of my
        
        4
        00:00:22.399 --> 00:00:25.679
        life and wherever it takes me i\'m down
        
        5
        00:00:25.679 --> 00:00:28.320
        for the ride baby don\'t you know i\'m
        """,
            TEST_NAME + "Checking if testCaptionsResponse.getFormattedString(withFormat: .vtt) is good."
        ) // vtt integrity checked with https://w3c.github.io/webvtt.js/parser.html
        
        XCTAssertEqual(
            testCaptionsResponse.getFormattedString(withFormat: .srt),
        """
        1
        00:00:13,119 --> 00:00:16,199
        [Music]
        
        2
        00:00:16,559 --> 00:00:19,839
        i\'m good yeah i\'m feeling all right baby
        
        3
        00:00:19,839 --> 00:00:22,399
        i\'mma have the best night of my
        
        4
        00:00:22,399 --> 00:00:25,679
        life and wherever it takes me i\'m down
        
        5
        00:00:25,679 --> 00:00:28,320
        for the ride baby don\'t you know i\'m
        """,
            TEST_NAME + "Checking if testCaptionsResponse.getFormattedString(withFormat: .srt) is good."
        ) // srt integrity checked with https://taoning2014.github.io/srt-validator-website/index.html
        
        XCTAssertTrue(requestResult.downloadFormats.compactMap({$0 as? VideoDownloadFormat}).allSatisfy({$0.is360 == false}), TEST_NAME + "Checking if the is360 property is correctly set -> has to be false")
        
        // test 360 video
        let video360result = try await YTVideo(videoId: "yVLfEHXQk08").fetchStreamingInfosThrowing(youtubeModel: YTM)
        XCTAssertTrue(video360result.downloadFormats.compactMap({$0 as? VideoDownloadFormat}).allSatisfy({$0.is360 == true}), TEST_NAME + "Checking if the is360 property is correctly set -> has to be true")
    }
    
    func testVideoInfosWithDownloadFormatsResponse() async throws {
        let TEST_NAME = "Test: testVideoInfosWithDownloadFormatsResponse() -> "
                
        try VideoInfosWithDownloadFormatsResponse.removePlayerFilesFromDisk()
        
        for video in [YTVideo(videoId: "dSDbwfXX5_I"), YTVideo(videoId: "3ryID_SwU5E")] as [YTVideo] {
            
            let requestResult = try await video.fetchStreamingInfosWithDownloadFormatsThrowing(youtubeModel: YTM)
                        
            XCTAssertNotEqual(requestResult.downloadFormats.count, 0, TEST_NAME + "Checking if requestResult.downloadFormats is empty")
            XCTAssertNotEqual(requestResult.defaultFormats.count, 0, TEST_NAME + "Checking if requestResult.defaultFormats is empty")
            XCTAssertNotEqual(requestResult.videoInfos.streamingURL, nil, TEST_NAME + "Checking if requestResult.videoInfos.streamingURL is empty")
        }
         
    }

    func testAutoCompletionResponse() async throws {
        YTM.selectedLocale = "en-US"
        
        let TEST_NAME = "Test: testAutoCompletionResponse() -> "
        
        let query: String = "hugo"
        
        let requestResult = try await AutoCompletionResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: query])
                
        XCTAssertEqual(requestResult.initialQuery, query, TEST_NAME + "Checking if query and initialQuery are equal")
        XCTAssertNotEqual(requestResult.autoCompletionEntries.count, 0, TEST_NAME + "Checking if requestResult.autoCompletionEntries is empty")
    }
    
    func testMemberOnlyVideo() async throws {
        if YTM.visitorData == "" {
            guard let visitorData = try await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "home"]).visitorData else { XCTFail("VisitorData is not present in SearchResponse."); return }
            YTM.visitorData = visitorData
        }
        
        self.YTM.alwaysUseCookies = false
        let testMemberOnlyVideoChannel = YTChannel(channelId: "UCXuqSBlHAE6Xw-yeJA0Tunw")
        
        let memberOnlyTestChannel = try await testMemberOnlyVideoChannel.fetchInfosThrowing(youtubeModel: YTM)
        let memberOnlyVideos = try await memberOnlyTestChannel.getChannelContentThrowing(forType: .videos, youtubeModel: YTM)
        let memberOnlyVideo = (memberOnlyVideos.currentContent as? ChannelInfosResponse.Videos)?.items.first(where: {($0 as? YTVideo)?.memberOnly == true}) as? YTVideo
        guard let memberOnlyVideo = memberOnlyVideo else { return }
        do {
            _ = try await VideoInfosResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: memberOnlyVideo.videoId])
            XCTFail("Video should not be able to be played")
        } catch {}
        self.YTM.alwaysUseCookies = true
    }
    
    func testChannelInfosResponse() async throws {
        let TEST_NAME = "Test: testChannelInfosResponse() -> "
            
        if YTM.visitorData == "" {
            guard let visitorData = try await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "home"]).visitorData else { XCTFail("VisitorData is not present in SearchResponse."); return }
            YTM.visitorData = visitorData
        }
        
        let videoResult = try await VideoInfosResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "bvUNXch3rdI"]) /// T-Series' video because they have continuation in every category
                
        guard let channel = videoResult.channel, channel.channelId != "" else { XCTFail(TEST_NAME + "The channel in the retrieved video is not defined (structure nil or channelId empty)."); return }
        
        let mainRequestResult = try await channel.fetchInfosThrowing(youtubeModel: YTM)
                
        XCTAssertNotNil(mainRequestResult.videoCount, TEST_NAME + "Checking if mainRequestResult.videosCount is not nil")
        
        /// Testing ChannelContent fetching, Videos, Shorts, Directs and Playlists
        
        /// Videos
        var videoRequestResult = try await mainRequestResult.getChannelContentThrowing(forType: .videos, youtubeModel: YTM)
                
        XCTAssertEqual(videoRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if videoRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(videoRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if videoRequestResult.channelId is equal to videoResult.channel.channelId")
        
        /// Test continuation
        let videoRequestContinuationResult = try await videoRequestResult.getChannelContentContinuationThrowing(ChannelInfosResponse.Videos.self, youtubeModel: YTM)
        
        videoRequestResult.mergeListableChannelContentContinuation(videoRequestContinuationResult)
        
        /// Shorts
        let shortsRequestResult = try await mainRequestResult.getChannelContentThrowing(forType: .shorts, youtubeModel: YTM)
                
        XCTAssertEqual(shortsRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if shortsRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(shortsRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if shortsRequestResult.channelId is equal to videoResult.channel.channelId")
        
        XCTAssertFalse((shortsRequestResult.currentContent as? ChannelInfosResponse.Shorts)?.items.isEmpty ?? true)
                
        /// Test continuation
        let shortsRequestContinuationResult = try await shortsRequestResult.getChannelContentContinuationThrowing(ChannelInfosResponse.Shorts.self, youtubeModel: YTM)
        
        XCTAssertFalse(shortsRequestContinuationResult.contents?.items.isEmpty ?? true)

        videoRequestResult.mergeListableChannelContentContinuation(shortsRequestContinuationResult)
        
                
        /// Directs
        let directsRequestResult = try await mainRequestResult.getChannelContentThrowing(forType: .directs, youtubeModel: YTM)
                
        XCTAssertEqual(directsRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if directsRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(directsRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if directsRequestResult.channelId is equal to videoResult.channel.channelId")
        XCTAssertFalse((directsRequestResult.currentContent as? ChannelInfosResponse.Directs)?.items.isEmpty ?? true)
        
        /// Test continuation
        let directsRequestContinuationResult = try await directsRequestResult.getChannelContentContinuationThrowing(ChannelInfosResponse.Directs.self, youtubeModel: YTM)
        
        XCTAssertFalse(directsRequestContinuationResult.contents?.items.isEmpty ?? true)
        
        videoRequestResult.mergeListableChannelContentContinuation(directsRequestContinuationResult)
        
                
        /// Playlists
        let playlistsRequestResult = try await mainRequestResult.getChannelContentThrowing(forType: .playlists, youtubeModel: YTM)
                
        XCTAssertEqual(playlistsRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if playlistsRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(playlistsRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if playlistsRequestResult.channelId is equal to videoResult.channel.channelId")
        XCTAssertFalse((playlistsRequestResult.currentContent as? ChannelInfosResponse.Playlists)?.items.isEmpty ?? true)
        
        /// Test continuation
        let playlistRequestContinuationResult = try await playlistsRequestResult.getChannelContentContinuationThrowing(ChannelInfosResponse.Playlists.self, youtubeModel: YTM)
        
        XCTAssertFalse(playlistRequestContinuationResult.contents?.items.isEmpty ?? true)
        
        videoRequestResult.mergeListableChannelContentContinuation(playlistRequestContinuationResult)
    }
    
    func testGetPlaylistInfos() async throws {
        let TEST_NAME = "Test: testGetPlaylistInfos() -> "
        
        let playlist = YTPlaylist(playlistId: "VLPLw-VjHDlEOgs658kAHR_LAaILBXb-s6Q5")
        
        var playlistInfosResult = try await playlist.fetchVideosThrowing(youtubeModel: YTM)
                
        XCTAssertFalse(playlistInfosResult.results.isEmpty)
        XCTAssertNotNil(playlistInfosResult.title)
        XCTAssertNotNil(playlistInfosResult.channel.first?.name)
        
        let playlistContinuation = try await playlistInfosResult.fetchContinuationThrowing(youtubeModel: YTM)
        
        XCTAssertFalse(playlistContinuation.results.isEmpty)
                
        let videoCount = playlistInfosResult.results.count + playlistContinuation.results.count
        playlistInfosResult.mergeWithContinuation(playlistContinuation)
        XCTAssertEqual(playlistInfosResult.results.count, videoCount, TEST_NAME + "Checking if the merge operation was successful. (videos count)")
        XCTAssertEqual(playlistInfosResult.continuationToken, playlistContinuation.continuationToken, TEST_NAME + "Checking if the merge operation was successful. (continuation token)")
    }
    
    func testHomeResponse() async throws {
        YTM.cookies = self.cookies
        let TEST_NAME = "Test: testHomeResponse() -> "
            
        var homeMenuResult = try await HomeScreenResponse.sendThrowingRequest(youtubeModel: YTM, data: [:], useCookies: true)
        guard homeMenuResult.continuationToken != nil else {
            // Could fail because sometimes YouTube gives an empty page telling you to start browsing. We check this case here.
            if !(homeMenuResult.results.count == 0 && homeMenuResult.visitorData != nil) {
                XCTFail(TEST_NAME + "Checking if homeMenuResult.continuationToken is defined.");
            } // else: YouTube might not give any result nor continuation if no account is connected (you'd have to activate the history).
            return
        }
        
        XCTAssertNotNil(homeMenuResult.visitorData, TEST_NAME + "Checking if homeMenuResult.visitorData is defined.")
        
        let homeMenuContinuationResult = try await homeMenuResult.fetchContinuationThrowing(youtubeModel: YTM, useCookies: true)
                
        guard homeMenuContinuationResult.continuationToken != nil else { XCTFail(TEST_NAME + "Checking if homeMenuContinuationResult.continuationToken is defined."); return }
        
        let videosCount = homeMenuResult.results.count + homeMenuContinuationResult.results.count
        
        homeMenuResult.mergeContinuation(homeMenuContinuationResult)
        XCTAssertEqual(homeMenuResult.results.count, videosCount, TEST_NAME + "Checking if the merge operation was successful (videos count).")
        XCTAssertEqual(homeMenuResult.continuationToken, homeMenuContinuationResult.continuationToken, TEST_NAME + "Checking if the merge operation was successful (continuationToken).")
    }
    
    /// The following tests can't be done without some Account's cookies
    func testAccountInfos() async throws {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testAccountInfos() -> "
        YTM.cookies = cookies
        
        let response = try await AccountInfosResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
                
        guard !response.isDisconnected else { XCTFail(TEST_NAME + "Checking if the cookies are valid."); return }
        
        /// Could potentially fail if the cookies' account does not have a channel.
        XCTAssertNotNil(response.channelHandle, TEST_NAME + "Checking if the channelHandle has been extracted (may have failed because your account does not have a channel).")
        XCTAssertNotNil(response.name, TEST_NAME + "Checking if the name of the account has been extracted.")
        XCTAssertNotEqual(response.avatar.count, 0, TEST_NAME + "Checking if the avatar of the account has been extracted.")
    }
    
    func testAccountLibrary() async throws {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testAccountLibrary() -> "
        YTM.cookies = cookies
        
        let response = try await AccountLibraryResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
                
        guard !response.isDisconnected else { XCTFail(TEST_NAME + "Checking if cookies were defined"); return }
        
        //XCTAssertNotEqual(response.accountStats.count, 0, TEST_NAME + "Checking if account's stats have been extracted.") // has been removed by YouTube
        XCTAssertNotNil(response.history, TEST_NAME + "Checking if history has been extracted.")
        XCTAssertNotNil(response.likes, TEST_NAME + "Checking if likes has been extracted.")
        XCTAssertNotNil(response.watchLater, TEST_NAME + "Checking if watchLater has been extracted.")
        XCTAssertNotEqual(response.playlists.count, 0, TEST_NAME + "Checking if account's playlists have been extracted.")
    }
    
    func testAccountPlaylists() async throws {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testAccountPlaylists() -> "
        YTM.cookies = cookies
        
        let response = try await AccountPlaylistsResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
                
        guard !response.isDisconnected else { XCTFail(TEST_NAME + "Checking if cookies were defined"); return }
        
        XCTAssertNotEqual(response.results.count, 0, TEST_NAME + "Checking if account's playlists have been extracted.")
        
        let firstPlaylist = response.results.first!
        
        XCTAssertNotNil(firstPlaylist.title, TEST_NAME + "Checking if the title of the first playlist has been extracted.")
        XCTAssertNotEqual(firstPlaylist.thumbnails.count, 0, TEST_NAME + "Checking if the thumbnails of the first playlist have been extracted.")
        XCTAssertNotNil(firstPlaylist.playlistId, TEST_NAME + "Checking if the playlistId of the first playlist has been extracted.")
    }
    
    func testCreateEmptyPlaylist() async throws {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testCreateEmptyPlaylist() -> "
        YTM.cookies = cookies
        
        let newPlaylistName = "YouTubeKitTest-\(UUID().uuidString)"

        let creationResponse = try await CreatePlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query : newPlaylistName, .params: YTPrivacy.private.rawValue])
        
        guard !creationResponse.isDisconnected else { XCTFail(TEST_NAME + "Checking if cookies were defined"); return }

        guard let createdPlaylistId = creationResponse.createdPlaylistId, let _ = creationResponse.playlistCreatorId else { XCTFail(TEST_NAME + "Checking if the playlist has been created."); return }
        
        XCTAssertNotNil(creationResponse.playlistCreatorId, TEST_NAME + "Checking if the playlist's creator has been extracted.")
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        
        // Deleting the playlist
        
        let deletePlaylistResponse = try await DeletePlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.browseId: createdPlaylistId])
        
        guard !deletePlaylistResponse.isDisconnected, deletePlaylistResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
    }
    
    func testPlaylistActions() async throws {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testPlaylistActions() -> "
        YTM.cookies = cookies
        
        let newPlaylistName = "YouTubeKitTest-\(UUID().uuidString)"
        
        let firstVideoToAddId = "peIBCNTY8hA"
        let secondVideoToAddId = "3ryID_SwU5E"
        let thirdVideoToAddId = "OlWdMCVtKJw"
        
        // Playlist creation part
        let creationResponse = try await CreatePlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query : newPlaylistName, .params: YTPrivacy.private.rawValue, .movingVideoId: firstVideoToAddId])
                
        guard !creationResponse.isDisconnected else { XCTFail(TEST_NAME + "Checking if cookies were defined"); return }
        
        guard let createdPlaylistId = creationResponse.createdPlaylistId, let playlistCreatorId = creationResponse.playlistCreatorId else { XCTFail(TEST_NAME + "Checking if the playlist has been created."); return }
        
        XCTAssertNotNil(creationResponse.playlistCreatorId, TEST_NAME + "Checking if the playlist's creator has been extracted.")
        
        // Let the playlist be updated in YouTube's servers
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let firstVideo = YTVideo(videoId: firstVideoToAddId)
        let allPlaylistResponse = try await firstVideo.fetchAllPossibleHostPlaylistsThrowing(youtubeModel: YTM)
                
        guard let createdPlaylistResult = allPlaylistResponse.playlistsAndStatus.first(where: {$0.playlist.playlistId.contains(createdPlaylistId) || createdPlaylistId.contains($0.playlist.playlistId)} /* avoid VL prefix notation bug*/) else { XCTFail(TEST_NAME + "Checking if the created playlist is listed among the other playlists."); return }
        
        XCTAssert(createdPlaylistResult.isVideoPresentInside, TEST_NAME + "Checking if video is present inside the new playlist.")
        XCTAssertEqual(createdPlaylistResult.playlist.privacy, YTPrivacy.private, TEST_NAME + "Checking if the privacy is correctly extracted.")
        
        
        // Video adding part
        let addVideoResponse = try await AddVideoToPlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoToAddId, .browseId: createdPlaylistId])
                
        guard !addVideoResponse.isDisconnected, addVideoResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(addVideoResponse.addedVideoId, secondVideoToAddId, TEST_NAME + "Checking if the video has been added.")
        guard let secondVideoIdInPlaylist = addVideoResponse.addedVideoIdInPlaylist else { XCTFail(TEST_NAME + "Checking if the videoIdInPlaylist has been extracted."); return }
        //XCTAssertEqual(addVideoResponse.playlistId, "VL" + createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        XCTAssertEqual(addVideoResponse.playlistCreatorId, playlistCreatorId, TEST_NAME + "Checking if the video has been added with the right account.")
        // Adding it a second time
        let addVideoResponse2 = try await AddVideoToPlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: thirdVideoToAddId, .browseId: createdPlaylistId])
                
        guard !addVideoResponse2.isDisconnected, addVideoResponse2.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(addVideoResponse2.addedVideoId, thirdVideoToAddId, TEST_NAME + "Checking if the video has been added.")
        guard let thirdVideoIdInPlaylist = addVideoResponse2.addedVideoIdInPlaylist else { XCTFail(TEST_NAME + "Checking if the videoIdInPlaylist has been extracted."); return }
        //XCTAssertEqual(addVideoResponse2.playlistId, "VL" + createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        XCTAssertEqual(addVideoResponse2.playlistCreatorId, playlistCreatorId, TEST_NAME + "Checking if the video has been added with the right account.")
        // Adding a third video
        let addVideoResponse3 = try await AddVideoToPlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoToAddId, .browseId: createdPlaylistId])
                
        guard !addVideoResponse3.isDisconnected, addVideoResponse3.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(addVideoResponse3.addedVideoId, secondVideoToAddId, TEST_NAME + "Checking if the video has been added.")
        guard let lastVideoIdInPlaylist = addVideoResponse3.addedVideoIdInPlaylist else { XCTFail(TEST_NAME + "Checking if the videoIdInPlaylist has been extracted."); return }
        //XCTAssertEqual(addVideoResponse3.playlistId, "VL" + createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        XCTAssertEqual(addVideoResponse3.playlistCreatorId, playlistCreatorId, TEST_NAME + "Checking if the video has been added with the right account.")
        
        // Moving the last video to the third position
        let moveVideoResponse = try await MoveVideoInPlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: lastVideoIdInPlaylist, .videoBeforeId: secondVideoIdInPlaylist, .browseId: createdPlaylistId])
        
        guard !moveVideoResponse.isDisconnected, moveVideoResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        //XCTAssertEqual(moveVideoResponse.playlistId, createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        // Moving the second video to the first position
        let moveVideoResponse2 = try await MoveVideoInPlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoIdInPlaylist, .browseId: createdPlaylistId])
        
        guard !moveVideoResponse2.isDisconnected, moveVideoResponse2.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        //XCTAssertEqual(moveVideoResponse2.playlistId, createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        
        // Checking the playlist's contents to verify if the videos were added and moved at the right places
        /*
         We did:
            Create playlist with video "peIBCNTY8hA"
            Add to playlist video "3ryID_SwU5E"
            Add to playlist video "OlWdMCVtKJw"
            Add to playlist video "3ryID_SwU5E"
            Move last video of the playlist ("3ryID_SwU5E") to the third position
            Move second video of the playlist ("3ryID_SwU5E") to the first position
        Then we should have a playlist like this:
            1. "3ryID_SwU5E"
            2. "peIBCNTY8hA"
            3. "3ryID_SwU5E"
            4. "OlWdMCVtKJw"
         */
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        let finalPlaylist = try await PlaylistInfosResponse.sendThrowingRequest(youtubeModel: YTM, data: [.browseId: createdPlaylistId], useCookies: true)
        
        guard finalPlaylist.results.map(\.videoId) == [secondVideoToAddId, firstVideoToAddId, secondVideoToAddId, thirdVideoToAddId] else { XCTFail(TEST_NAME + "Checking if all the addings and moves were correctly executed."); return }
        
        // Removing part
        let removeVideoResponse = try await RemoveVideoFromPlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: thirdVideoIdInPlaylist, .playlistEditToken: "CAFAAQ%3D%3D", .browseId: createdPlaylistId], useCookies: true) // playlistEditToken is hardcoded here, could lead to some error
                
        guard !removeVideoResponse.isDisconnected, removeVideoResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        let removeVideoResponse2 = try await RemoveVideoByIdFromPlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoToAddId, .browseId: createdPlaylistId], useCookies: true)
        
        guard !removeVideoResponse2.isDisconnected, removeVideoResponse2.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        // Checking the playlist
        let finalPlaylist2 = try await PlaylistInfosResponse.sendThrowingRequest(youtubeModel: YTM, data: [.browseId: createdPlaylistId], useCookies: true)
        
        guard finalPlaylist2.results.map({$0.videoId}) == [firstVideoToAddId] else { XCTFail(TEST_NAME + "Checking if all the removing were correctly executed."); return }
        
        // Deleting the playlist
        
        let deletePlaylistResponse = try await DeletePlaylistResponse.sendThrowingRequest(youtubeModel: YTM, data: [.browseId: createdPlaylistId])
        
        guard !deletePlaylistResponse.isDisconnected, deletePlaylistResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
    }
    
    func testHistoryResponse() async throws {
        func testResponse(query: String = "") async throws {
            let historyResponse = try await HistoryResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: query], useCookies: true)
                    
            XCTAssertNotNil(historyResponse.title, TEST_NAME + "Checking if historyResponse.title has been extracted.")
            XCTAssertNotEqual(historyResponse.results.count, 0, TEST_NAME + "Checking if historyResponse.results is not empty.")
            
            guard let firstVideoToken = (historyResponse.results.first?.contentsArray.first(where: {$0 as? HistoryResponse.HistoryBlock.VideoWithToken != nil}) as! HistoryResponse.HistoryBlock.VideoWithToken).suppressToken else { XCTFail(TEST_NAME + "Could not find a video with a suppressToken in the history"); return }
            
            try await historyResponse.removeVideoThrowing(withSuppressToken: firstVideoToken, youtubeModel: YTM)
            
            if let shortsBlock = (historyResponse.results.first?.contentsArray.first(where: {$0 as? HistoryResponse.HistoryBlock.ShortsBlock != nil}) as? HistoryResponse.HistoryBlock.ShortsBlock) {
                XCTAssertNotNil(shortsBlock.suppressTokens.compactMap({$0}), TEST_NAME + "Checking if suppressTokens of ShortBlock is not full of nil values.")
            }
            
            if historyResponse.continuationToken != nil {
                let continuationResponse = try await historyResponse.fetchContinuation(youtubeModel: YTM)
                
                XCTAssertNotEqual(continuationResponse.results.count, 0, TEST_NAME + "Checking if continuationResponse.results is not empty.")
                
                if let shortsBlock = (continuationResponse.results.first?.contentsArray.first(where: {$0 as? HistoryResponse.HistoryBlock.ShortsBlock != nil}) as? HistoryResponse.HistoryBlock.ShortsBlock) {
                    XCTAssertNotNil(shortsBlock.suppressTokens.compactMap({$0}), TEST_NAME + "Checking if suppressTokens of ShortBlock is not full of nil values.")
                }
            }
        }
        
        let TEST_NAME = "Test: testHistoryResponse() -> "
        guard cookies != "" else { return }
        YTM.cookies = cookies
        
        try await testResponse()
        
        try await testResponse(query: "test")
    }
    
    func testMoreVideoInfosResponse() async throws {
        let TEST_NAME = "Test: testMoreVideoInfosResponse() -> "
        YTM.cookies = cookies

        let video = YTVideo(videoId: "S1dN1NY36cY")

        var moreVideoInfosResponse = try await video.fetchMoreInfosThrowing(youtubeModel: YTM, useCookies: true)
                
        if cookies != "" {
            XCTAssertNotNil(moreVideoInfosResponse.authenticatedInfos, TEST_NAME + "Checking if the authenticationData has been extracted.")
            XCTAssertNotNil(moreVideoInfosResponse.authenticatedInfos?.likeStatus, TEST_NAME + "Checking if the authenticationData.likeStatus has been extracted.")
            XCTAssertNotNil(moreVideoInfosResponse.authenticatedInfos?.subscriptionStatus, TEST_NAME + "Checking if the authenticationData.subscriptionStatus has been extracted.") // Will fail if the account is the owner of the tested video.
        }
        
        XCTAssertNotNil(moreVideoInfosResponse.channel, TEST_NAME + "Checking if the channel has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.commentsCount, TEST_NAME + "Checking if the commentsCount has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.likesCount.defaultState, TEST_NAME + "Checking if the likesCount has been extracted.")
        XCTAssertNotEqual(moreVideoInfosResponse.recommendedVideos.count, 0, TEST_NAME + "Checking if some recommended videos are present.")
        XCTAssertNotNil(moreVideoInfosResponse.recommendedVideosContinuationToken, TEST_NAME + "Checking if the recommendedVideosContinuationToken has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.timePosted.postedDate, TEST_NAME + "Checking if the timePosted.postedDate has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.timePosted.relativePostedDate, TEST_NAME + "Checking if the timePosted.relativePostedDate has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.videoDescription, TEST_NAME + "Checking if the videoDescription has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.videoTitle, TEST_NAME + "Checking if the videoTitle has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.viewsCount.fullViewsCount, TEST_NAME + "Checking if the viewsCount.fullViewsCount has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.viewsCount.shortViewsCount, TEST_NAME + "Checking if the viewsCount.shortViewsCount has been extracted.")
        
        /// Fetch the continuation of the recommendedVideos
        let recommendedVideosContinuationResponse = try await moreVideoInfosResponse.getRecommendedVideosContinationThrowing(youtubeModel: YTM)
                
        guard !(moreVideoInfosResponse.recommendedVideos.isEmpty && recommendedVideosContinuationResponse.results.isEmpty) else { XCTFail(TEST_NAME + "No recommended videos in the first place nor with the continuationResponse."); return}
        
        XCTAssertNotEqual(recommendedVideosContinuationResponse.results.count, 0, TEST_NAME + "Checking if results for continuation have been extracted.")
        XCTAssertNotNil(recommendedVideosContinuationResponse.continuationToken, TEST_NAME + "Checking if continuationToken has been extracted.")
        let initialRecommendedVideosCount = moreVideoInfosResponse.recommendedVideos.count
        
        moreVideoInfosResponse.mergeRecommendedVideosContination(recommendedVideosContinuationResponse)
        XCTAssertEqual(initialRecommendedVideosCount + recommendedVideosContinuationResponse.results.count, moreVideoInfosResponse.recommendedVideos.count, TEST_NAME + "Checking if the merge operation was successful (arrays merging).")
        XCTAssertEqual(moreVideoInfosResponse.recommendedVideosContinuationToken, recommendedVideosContinuationResponse.continuationToken, TEST_NAME + "Checking if the merge operation was successful (continuationToken overwriting).")
    }
    
    func testLikeRequests() async throws {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testLikeRequests() -> "
        YTM.cookies = cookies
        
        let video = YTVideo(videoId: "JdFRjsEZrmU")
        
        let likeStatus: YTLikeStatus? = try await getCurrentLikeStatus()
        
        guard let likeStatus = likeStatus else { XCTFail(TEST_NAME + "Checking if likeStatus is defined"); return }
        
        let delay: UInt64 = 4_000_000_000
        
        try await Task.sleep(nanoseconds: delay) // introduce some delay to avoid a block from YouTube.
    
        switch likeStatus {
        case .liked:
            try await dislikeVideo()
            try await Task.sleep(nanoseconds: delay)
            try await removelikeVideo()
            try await Task.sleep(nanoseconds: delay)
            try await likeVideo()
        case .disliked:
            try await removelikeVideo()
            try await Task.sleep(nanoseconds: delay)
            try await likeVideo()
            try await Task.sleep(nanoseconds: delay)
            try await dislikeVideo()
        case .nothing:
            try await likeVideo()
            try await Task.sleep(nanoseconds: delay)
            try await dislikeVideo()
            try await Task.sleep(nanoseconds: delay)
            try await removelikeVideo()
        }
        
        func getCurrentLikeStatus() async throws -> YTLikeStatus? {
            let currentStatusResponse = try await video.fetchMoreInfosThrowing(youtubeModel: YTM, useCookies: true)
                        
            return currentStatusResponse.authenticatedInfos?.likeStatus
        }
        
        func dislikeVideo() async throws {
            try await video.dislikeVideoThrowing(youtubeModel: YTM)
                                    
            let localLikeStatus = try await getCurrentLikeStatus()
            guard localLikeStatus == .disliked else { XCTFail(TEST_NAME + "Checking if localLikeStatus is disliked"); return }
        }
        
        func likeVideo() async throws {
            try await video.likeVideoThrowing(youtubeModel: YTM)
                                    
            let localLikeStatus = try await getCurrentLikeStatus()
            guard localLikeStatus == .liked else { XCTFail(TEST_NAME + "Checking if localLikeStatus is liked"); return }
        }
        
        func removelikeVideo() async throws {
            try await video.removeLikeFromVideoThrowing(youtubeModel: YTM)
                        
            let localLikeStatus = try await getCurrentLikeStatus()
            guard localLikeStatus == .nothing else { XCTFail(TEST_NAME + "Checking if localLikeStatus is nothing"); return }
        }
    }
    
    func testSubscriptionRequests() async throws {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testSubscriptionRequests() -> "
        YTM.cookies = cookies
        
        let video = YTVideo(videoId: "-K8nQk-iZzs")
        
        let videoInfosResponse = try await getSubscriptionStatus()
        guard let currentStatus = videoInfosResponse?.authenticatedInfos?.subscriptionStatus, let channel = videoInfosResponse?.channel else { XCTFail(TEST_NAME + "Checking if subscriptionStatus and channelId are defined."); return }
        
        if currentStatus {
            try await unsubscribeToChannel()
            try await subscribeToChannel()
        } else {
            try await subscribeToChannel()
            try await unsubscribeToChannel()
        }
        
        func getSubscriptionStatus() async throws -> MoreVideoInfosResponse? {
            let videoResponse = try await video.fetchMoreInfosThrowing(youtubeModel: YTM, useCookies: true)
            
            XCTAssertNotNil(videoResponse.authenticatedInfos, TEST_NAME + "Checking if request has been authenticated.")
            return videoResponse
        }
        
        func subscribeToChannel() async throws {
            try await channel.subscribeThrowing(youtubeModel: YTM)
        }
        
        func unsubscribeToChannel() async throws {
            try await channel.unsubscribeThrowing(youtubeModel: YTM)
        }
    }
    
    @available(*, deprecated, message: "Trending tabs were removed by YouTube")
    func testTrendingTab() async throws {
        let TEST_NAME = "Test: testTrendingTab() -> "
        
        var baseTrendingResponse = try await TrendingVideosResponse.sendThrowingRequest(youtubeModel: YTM, data: [:])
        
        guard let mainTabName = baseTrendingResponse.currentContentIdentifier else {
            XCTFail(TEST_NAME + "currentContentIdentifier is not defined")
            return
        }
        
        XCTAssertNotNil(baseTrendingResponse.categoriesContentsStore[mainTabName], TEST_NAME + "currentContentIdentifier is not defined.")
        XCTAssert(!baseTrendingResponse.categoriesContentsStore[mainTabName]!.isEmpty, TEST_NAME + "currentContentIdentifier is empty.")
        XCTAssertNotNil(baseTrendingResponse.requestParams[mainTabName], TEST_NAME + "baseTrendingResponse.requestParams[mainTabName] is nil.")
        
        for availableTab in Array(baseTrendingResponse.requestParams.keys) where availableTab != mainTabName {
            let newResponse = try await baseTrendingResponse.getCategoryContentThrowing(forIdentifier: availableTab, youtubeModel: YTM)
            
            guard let tabName = newResponse.currentContentIdentifier else {
                XCTFail(TEST_NAME + "currentContentIdentifier is not defined for tab with supposed name \(availableTab).")
                return
            }
            
            XCTAssertEqual(tabName, availableTab, TEST_NAME + "tabName equal to availableTab.")
            
            XCTAssertNotNil(newResponse.categoriesContentsStore[tabName], TEST_NAME + "currentContentIdentifier is not defined for tab with name \(tabName).")
            XCTAssert(!newResponse.categoriesContentsStore[tabName]!.isEmpty, TEST_NAME + "currentContentIdentifier is empty for tab with name \(tabName).")
            XCTAssertNotNil(newResponse.requestParams[tabName], TEST_NAME + "newResponse.requestParams[mainTabName] is nil for with name \(tabName).")
            
            baseTrendingResponse.mergeTrendingResponse(newResponse)
            
            XCTAssertEqual(baseTrendingResponse.currentContentIdentifier, tabName, TEST_NAME + "tabName is not equal to currentContentIdentifier after merging to baseTrendingResponse.")
            XCTAssertEqual(baseTrendingResponse.categoriesContentsStore[tabName], newResponse.categoriesContentsStore[tabName], TEST_NAME + "baseTrendingResponse.categoriesContentsStore[tabName] is not equal to newResponse[tabName] after merging.")
            XCTAssertNotNil(baseTrendingResponse.categoriesContentsStore[mainTabName], TEST_NAME + "baseTrendingResponse.categoriesContentsStore[mainTabName] is nil after merging with response with categoryName: \"\(tabName)\"")
        }
        
        let secondBaseTrendingResponse = try await baseTrendingResponse.getCategoryContentThrowing(forIdentifier: mainTabName, youtubeModel: YTM)
        
        baseTrendingResponse.mergeTrendingResponse(secondBaseTrendingResponse)
        
        XCTAssertEqual(secondBaseTrendingResponse.currentContentIdentifier, mainTabName, TEST_NAME + "currentContentIdentifier is not equal to mainTabName after second request.")
        XCTAssertEqual(baseTrendingResponse.categoriesContentsStore[mainTabName], secondBaseTrendingResponse.categoriesContentsStore[mainTabName], TEST_NAME + "baseTrendingResponse.categoriesContentsStore[tabName] is not equal to secondBaseTrendingResponse[tabName] after merging.")
    }
    
    func testAccountSubscriptionsResponse() async throws {
        let TEST_NAME = "Test: testAccountSubscriptionsResponse() -> "
        guard cookies != "" else { return }
        YTM.cookies = cookies
        
        var accountSubscriptionsResponse = try await AccountSubscriptionsResponse.sendThrowingRequest(youtubeModel: YTM, data: [:], useCookies: true)
        
        XCTAssert(!accountSubscriptionsResponse.isDisconnected, TEST_NAME + "Account is disconnected.")
        XCTAssertNil(accountSubscriptionsResponse.visitorData, TEST_NAME + "visitorData is not nil (but should never be extracted).")
                
        XCTAssertNotEqual(accountSubscriptionsResponse.results.count, 0, TEST_NAME + "Checking if accountSubscriptionsResponse.results is not empty.")
        
        if accountSubscriptionsResponse.continuationToken != nil {
            let continuationResponse = try await accountSubscriptionsResponse.fetchContinuation(youtubeModel: YTM)
            
            XCTAssertNotEqual(continuationResponse.results.count, 0, TEST_NAME + "Checking if continuationResponse.results is not empty.")
            
            let oldChannelsCount = accountSubscriptionsResponse.results.count
            
            accountSubscriptionsResponse.mergeContinuation(continuationResponse)
            
            XCTAssertEqual(accountSubscriptionsResponse.results.count, oldChannelsCount + continuationResponse.results.count, TEST_NAME + "accountSubscriptionsResponse.results.count is not equal to oldChannelsCount + continuationResponse.results.count")
            XCTAssertEqual(accountSubscriptionsResponse.continuationToken, continuationResponse.continuationToken, TEST_NAME + "continuationToken hasn't been merged.")
        }
    }
    
    func testAccountSubscriptionsFeedResponse() async throws {
        let TEST_NAME = "Test: testAccountSubscriptionsFeedResponse() -> "
        guard cookies != "" else { return }
        YTM.cookies = cookies
        
        var accountSubscriptionsFeedResponse = try await AccountSubscriptionsFeedResponse.sendThrowingRequest(youtubeModel: YTM, data: [:], useCookies: true)
        
        XCTAssert(!accountSubscriptionsFeedResponse.isDisconnected, TEST_NAME + "Account is disconnected.")
        XCTAssertNil(accountSubscriptionsFeedResponse.visitorData, TEST_NAME + "visitorData is not nil (but should never be extracted).")
                
        XCTAssertNotEqual(accountSubscriptionsFeedResponse.results.count, 0, TEST_NAME + "Checking if accountSubscriptionsFeedResponse.results is not empty.")
        
        if accountSubscriptionsFeedResponse.continuationToken != nil {
            let continuationResponse = try await accountSubscriptionsFeedResponse.fetchContinuation(youtubeModel: YTM)
            
            XCTAssertNotEqual(continuationResponse.results.count, 0, TEST_NAME + "Checking if continuationResponse.results is not empty.")
            
            let oldChannelsCount = accountSubscriptionsFeedResponse.results.count
            
            accountSubscriptionsFeedResponse.mergeContinuation(continuationResponse)
            
            XCTAssertEqual(accountSubscriptionsFeedResponse.results.count, oldChannelsCount + continuationResponse.results.count, TEST_NAME + "accountSubscriptionsFeedResponse.results.count is not equal to oldChannelsCount + continuationResponse.results.count")
            XCTAssertEqual(accountSubscriptionsFeedResponse.continuationToken, continuationResponse.continuationToken, TEST_NAME + "continuationToken hasn't been merged.")
        }
    }
    
    func testVideoComments() async throws {
        let TEST_NAME = "Test: testVideoComments() -> "
        
        YTM.cookies = self.cookies
        
        let video = YTVideo(videoId: "KkCXLABwHP0")
        
        let videoResponse = try await video.fetchMoreInfosThrowing(youtubeModel: YTM, useCookies: true)
        
        guard let commentsToken = videoResponse.commentsContinuationToken else {
            XCTFail(TEST_NAME + "videoResponse.commentsContinuationToken is nil.")
            return
        }
        
        var videoCommentsResponse = try await VideoCommentsResponse.sendThrowingRequest(youtubeModel: YTM, data: [.continuation: commentsToken], useCookies: true)
        
        XCTAssertNil(videoCommentsResponse.visitorData, TEST_NAME + "visitorData is not nil but it should.")
        
        XCTAssert(!videoCommentsResponse.results.isEmpty, TEST_NAME + "videoCommentsResponse.results is empty")
        
        let firstComment = videoCommentsResponse.results.first!
        
        XCTAssertNotNil(firstComment.totalRepliesNumber)
        XCTAssertNotNil(firstComment.timePosted)
        XCTAssertNotEqual(firstComment.text.count, 0)
        XCTAssertNotNil(firstComment.sender)
        XCTAssertNotNil(firstComment.sender?.name)
        XCTAssertNotNil(firstComment.sender?.thumbnails.first)
        XCTAssertNotNil(firstComment.replyLevel)
        XCTAssertNotNil(firstComment.likesCountWhenUserLiked)
        XCTAssertNotNil(firstComment.likesCount)
        XCTAssertNotNil(firstComment.likeState)
        XCTAssertNotNil(firstComment.isLikedByVideoCreator)
        XCTAssertNotEqual(firstComment.commentIdentifier.count, 0)
        
        XCTAssertNotNil(firstComment.actionsParams[.repliesContinuation])
        
        let moreRepliesResponse = try await firstComment.fetchRepliesContinuation(youtubeModel: YTM, useCookies: true)
        XCTAssertNotNil(moreRepliesResponse.continuationToken, TEST_NAME + "continuationToken of moreRepliesResponse is nil.")
        
        XCTAssert(!moreRepliesResponse.results.isEmpty, TEST_NAME + "moreRepliesResponse.results is empty")
        
        let firstCommentFromContinuation = moreRepliesResponse.results.first!
        
        XCTAssertNotNil(firstCommentFromContinuation.totalRepliesNumber)
        XCTAssertNotNil(firstCommentFromContinuation.timePosted)
        XCTAssertNotEqual(firstCommentFromContinuation.text.count, 0)
        XCTAssertNotNil(firstCommentFromContinuation.sender)
        XCTAssertNotNil(firstCommentFromContinuation.replyLevel)
        XCTAssertNotNil(firstCommentFromContinuation.likesCountWhenUserLiked)
        XCTAssertNotNil(firstCommentFromContinuation.likesCount)
        XCTAssertNotNil(firstCommentFromContinuation.likeState)
        XCTAssertNotNil(firstCommentFromContinuation.isLikedByVideoCreator)
        XCTAssertNotEqual(firstCommentFromContinuation.commentIdentifier.count, 0)
        
        
        XCTAssertNotNil(videoCommentsResponse.continuationToken)
        
        let continuation = try await videoCommentsResponse.fetchContinuationThrowing(youtubeModel: YTM, useCookies: true)
        
        XCTAssertNotNil(continuation.continuationToken, TEST_NAME + "continuationToken of continuation is nil.")
        
        XCTAssert(!continuation.results.isEmpty, TEST_NAME + "continuation.results is empty")
        
        let firstCommentFromNormalContinuation = continuation.results.first!
        
        XCTAssertNotNil(firstCommentFromNormalContinuation.totalRepliesNumber)
        XCTAssertNotNil(firstCommentFromNormalContinuation.timePosted)
        XCTAssertNotEqual(firstCommentFromNormalContinuation.text.count, 0)
        XCTAssertNotNil(firstCommentFromNormalContinuation.sender)
        XCTAssertNotNil(firstCommentFromNormalContinuation.replyLevel)
        XCTAssertNotNil(firstCommentFromNormalContinuation.likesCountWhenUserLiked)
        XCTAssertNotNil(firstCommentFromNormalContinuation.likesCount)
        XCTAssertNotNil(firstCommentFromNormalContinuation.likeState)
        XCTAssertNotNil(firstCommentFromNormalContinuation.isLikedByVideoCreator)
        XCTAssertNotEqual(firstCommentFromNormalContinuation.commentIdentifier.count, 0)
        
        let oldCount = videoCommentsResponse.results.count
        
        videoCommentsResponse.mergeContinuation(continuation)
        
        XCTAssertEqual(videoCommentsResponse.results.count, oldCount + continuation.results.count)
        XCTAssertEqual(videoCommentsResponse.continuationToken, continuation.continuationToken)
        
        if let commentToTranslate = videoCommentsResponse.results.first(where: {$0.actionsParams[.translate] != nil}) {
            let translationResponse = try await commentToTranslate.translateText(youtubeModel: YTM)
            XCTAssert(!translationResponse.translation.isEmpty)
        }
    }
    
    func testAuthActionsVideoComments() async throws {
        let TEST_NAME = "Test: testVideoComments() -> "
        
        YTM.cookies = self.cookies
        
        guard self.cookies != "" else { return } // start of the tests that require a google account
        
        let video = YTVideo(videoId: "KkCXLABwHP0")
        
        let videoResponse = try await video.fetchMoreInfosThrowing(youtubeModel: YTM, useCookies: true)
        
        guard let commentsToken = videoResponse.commentsContinuationToken else {
            XCTFail(TEST_NAME + "videoResponse.commentsContinuationToken is nil.")
            return
        }
                
        let videoCommentsResponse = try await VideoCommentsResponse.sendThrowingRequest(youtubeModel: YTM, data: [.continuation: commentsToken], useCookies: true)
        
        guard let commentCreationToken = videoCommentsResponse.commentCreationToken else { XCTFail(TEST_NAME + "commentCreationToken is nil."); return }
        
        let createCommentText = "YouTubeKit test ?=/\\\""
        let createCommentResponse = try await CreateCommentResponse.sendThrowingRequest(youtubeModel: YTM, data: [.params: commentCreationToken, .text: createCommentText])
        
        XCTAssert(!createCommentResponse.isDisconnected)
        XCTAssert(createCommentResponse.success)
        guard let createdComment = createCommentResponse.newComment else { XCTFail(TEST_NAME + "Couldn't retrieve newly created comment."); return }
        
        XCTAssertEqual(createdComment.text, createCommentText)
        try await Task.sleep(nanoseconds: 60_000_000_000) // time for the comment to be indexed by youtube
        
        try await createdComment.commentAction(youtubeModel: YTM, action: .like)
        try await Task.sleep(nanoseconds: 5_000_000_000)
        try await createdComment.commentAction(youtubeModel: YTM, action: .removeLike)
        try await Task.sleep(nanoseconds: 5_000_000_000)
        try await createdComment.commentAction(youtubeModel: YTM, action: .dislike)
        try await Task.sleep(nanoseconds: 5_000_000_000)
        try await createdComment.commentAction(youtubeModel: YTM, action: .removeDislike)
        try await Task.sleep(nanoseconds: 5_000_000_000)
        try await createdComment.editComment(withNewText: "YouTubeKit", youtubeModel: YTM)
        try await Task.sleep(nanoseconds: 5_000_000_000)
        let reply = try await createdComment.replyToComment(youtubeModel: YTM, text: "Yes!")
        guard let replyComment = reply.newComment else { XCTFail(TEST_NAME + "Couldn't retrieve newly created reply."); return}
        try await Task.sleep(nanoseconds: 60_000_000_000)
        try await replyComment.editComment(withNewText: "No!", youtubeModel: YTM)
        try await Task.sleep(nanoseconds: 5_000_000_000)
        try await createdComment.commentAction(youtubeModel: YTM, action: .delete)
    }
    
    /// Use this to test responses from local files
    func testLocalFile() throws {
        guard false else { return } // should not be run by default
        
        let fileURL = URL(string: "file:///....json")!
        
        let data = try Data(contentsOf: fileURL)
        
        let result = try AccountLibraryResponse.decodeData(data: data)
        
        print(result)
    }
}
