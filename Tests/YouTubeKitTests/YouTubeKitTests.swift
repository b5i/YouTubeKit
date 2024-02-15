import XCTest
@testable import YouTubeKit

final class YouTubeKitTests: XCTestCase {
    private let YTM = YouTubeModel()
    
    /// Keep them secret! Make sure you remove them after having tested YouTubeKit.
    private let cookies = ""
    
    func testCreateCustomHeaders() async {
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
            
            /// String representing a name.
            var name: String = ""
            
            /// String representing a surname.
            var surname: String = ""
            
            static func decodeData(data: Data) -> NameAndSurnameResponse {
                /// Initialize an empty response.
                var nameAndSurnameResponse = NameAndSurnameResponse()
                // Extracts the data of the JSON, can also be done using normal JSONDecoder().decode(NameAndSurnameResponse.self, data) by making NameAndSurnameResponse conform to Codable protocol as the JSON is not very complex here.
                
                let json = JSON(data)
                
                nameAndSurnameResponse.name = json["name"].stringValue
                nameAndSurnameResponse.surname = json["surname"].stringValue
                
                return nameAndSurnameResponse
            }
        }
        
        let NAME_SHOULD_BE = "myName"
        let SURNAME_SHOULD_BE = "mySurname"
        
        let (result, error) = await NameAndSurnameResponse.sendRequest(youtubeModel: YTM, data: [:])
        
        if let result = result, error == nil {
            if result.name == NAME_SHOULD_BE && result.surname == SURNAME_SHOULD_BE {
                XCTAssert(true, TEST_NAME + "successful!")
            } else {
                XCTFail(TEST_NAME + "the name != \(NAME_SHOULD_BE) actually (\(result.name)) or surname != \(SURNAME_SHOULD_BE) actually (\(result.surname))")
            }
        } else {
            XCTFail(TEST_NAME + "the result is not defined (result = \(String(describing: result))) or the error is not nil (error = \(String(describing: error))")
        }
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
    
    func testRestrictedSearch() async {
        let TEST_NAME = "Test: testRestrictedSearch() -> "
        
        let (requestResult, error) = await SearchResponse.Restricted.sendRequest(youtubeModel: YTM, data: [.query: "mrbeast"])
        
        guard let requestResult = requestResult else { XCTFail(TEST_NAME + "Checking if requestResult is defined., error -> \(String(describing: error))"); return}
        
        XCTAssertNotEqual(requestResult.results.count, 0, TEST_NAME + "Checking if there is actual results in requestResult.results")
    }
    
    func testSearchResponse() async throws {
        let TEST_NAME = "Test: testSearchResponse() -> "
        
        let testVideo = """
            {\n  \"inlinePlaybackEndpoint\" : {\n    \"watchEndpoint\" : {\n      \"playerParams\" : \"YAHIAQE%3D\",\n      \"videoId\" : \"3jS_yEK8qVI\",\n      \"playerExtraUrlParams\" : [\n        {\n          \"key\" : \"inline\",\n          \"value\" : \"1\"\n        }\n      ],\n      \"watchEndpointSupportedOnesieConfig\" : {\n        \"html5PlaybackOnesieConfig\" : {\n          \"commonConfig\" : {\n            \"url\" : \"https:\\/\\/rr2---sn-1gi7znek.googlevideo.com\\/initplayback?source=youtube&oeis=1&c=WEB&oad=3200&ovd=3200&oaad=11000&oavd=11000&ocs=700&oewis=1&oputc=1&ofpcc=1&beids=24350017&msp=1&odepv=1&id=de34bfc842bca952&ip=31.10.173.100&initcwndbps=2717500&mt=1687187839&oweuc=\"\n          }\n        }\n      }\n    },\n    \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0yBnNlYXJjaFIHbXJiZWFzdJoBAxD0JA==\",\n    \"commandMetadata\" : {\n      \"webCommandMetadata\" : {\n        \"url\" : \"\\/watch?v=3jS_yEK8qVI&pp=YAHIAQE%3D\",\n        \"rootVe\" : 3832,\n        \"webPageType\" : \"WEB_PAGE_TYPE_WATCH\"\n      }\n    }\n  },\n  \"searchVideoResultEntityKey\" : \"EgszalNfeUVLOHFWSSDnAigB\",\n  \"channelThumbnailSupportedRenderers\" : {\n    \"channelThumbnailWithLinkRenderer\" : {\n      \"accessibility\" : {\n        \"accessibilityData\" : {\n          \"label\" : \"Accéder à la chaîne\"\n        }\n      },\n      \"navigationEndpoint\" : {\n        \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\",\n        \"browseEndpoint\" : {\n          \"canonicalBaseUrl\" : \"\\/@MrBeast\",\n          \"browseId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\"\n        },\n        \"commandMetadata\" : {\n          \"webCommandMetadata\" : {\n            \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\",\n            \"rootVe\" : 3611,\n            \"webPageType\" : \"WEB_PAGE_TYPE_CHANNEL\",\n            \"url\" : \"\\/@MrBeast\"\n          }\n        }\n      },\n      \"thumbnail\" : {\n        \"thumbnails\" : [\n          {\n            \"height\" : 68,\n            \"width\" : 68,\n            \"url\" : \"https:\\/\\/yt3.ggpht.com\\/ytc\\/AGIKgqNRr7IEdQ7TplsO8BG-KjG19aCcCpVjiV9l36-9lQ=s68-c-k-c0x00ffffff-no-rj\"\n          }\n        ]\n      }\n    }\n  },\n  \"shortViewCountText\" : {\n    \"accessibility\" : {\n      \"accessibilityData\" : {\n        \"label\" : \"208 millions de vues\"\n      }\n    },\n    \"simpleText\" : \"208 M de vues\"\n  },\n  \"videoId\" : \"3jS_yEK8qVI\",\n  \"shortBylineText\" : {\n    \"runs\" : [\n      {\n        \"navigationEndpoint\" : {\n          \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\",\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\",\n              \"url\" : \"\\/@MrBeast\",\n              \"rootVe\" : 3611,\n              \"webPageType\" : \"WEB_PAGE_TYPE_CHANNEL\"\n            }\n          },\n          \"browseEndpoint\" : {\n            \"browseId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\",\n            \"canonicalBaseUrl\" : \"\\/@MrBeast\"\n          }\n        },\n        \"text\" : \"MrBeast\"\n      }\n    ]\n  },\n  \"badges\" : [\n    {\n      \"metadataBadgeRenderer\" : {\n        \"accessibilityData\" : {\n          \"label\" : \"Sous-titres\"\n        },\n        \"trackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\",\n        \"style\" : \"BADGE_STYLE_TYPE_SIMPLE\",\n        \"label\" : \"Sous-titres\"\n      }\n    }\n  ],\n  \"longBylineText\" : {\n    \"runs\" : [\n      {\n        \"navigationEndpoint\" : {\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"webPageType\" : \"WEB_PAGE_TYPE_CHANNEL\",\n              \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\",\n              \"rootVe\" : 3611,\n              \"url\" : \"\\/@MrBeast\"\n            }\n          },\n          \"browseEndpoint\" : {\n            \"browseId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\",\n            \"canonicalBaseUrl\" : \"\\/@MrBeast\"\n          },\n          \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\"\n        },\n        \"text\" : \"MrBeast\"\n      }\n    ]\n  },\n  \"ownerText\" : {\n    \"runs\" : [\n      {\n        \"navigationEndpoint\" : {\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"url\" : \"\\/@MrBeast\",\n              \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\",\n              \"rootVe\" : 3611,\n              \"webPageType\" : \"WEB_PAGE_TYPE_CHANNEL\"\n            }\n          },\n          \"browseEndpoint\" : {\n            \"browseId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\",\n            \"canonicalBaseUrl\" : \"\\/@MrBeast\"\n          },\n          \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\"\n        },\n        \"text\" : \"MrBeast\"\n      }\n    ]\n  },\n  \"menu\" : {\n    \"menuRenderer\" : {\n      \"accessibility\" : {\n        \"accessibilityData\" : {\n          \"label\" : \"Menu d\'actions\"\n        }\n      },\n      \"items\" : [\n        {\n          \"menuServiceItemRenderer\" : {\n            \"serviceEndpoint\" : {\n              \"commandMetadata\" : {\n                \"webCommandMetadata\" : {\n                  \"sendPost\" : true\n                }\n              },\n              \"clickTrackingParams\" : \"CLIDEP6YBBgNIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n              \"signalServiceEndpoint\" : {\n                \"actions\" : [\n                  {\n                    \"clickTrackingParams\" : \"CLIDEP6YBBgNIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n                    \"addToPlaylistCommand\" : {\n                      \"onCreateListCommand\" : {\n                        \"commandMetadata\" : {\n                          \"webCommandMetadata\" : {\n                            \"apiUrl\" : \"\\/youtubei\\/v1\\/playlist\\/create\",\n                            \"sendPost\" : true\n                          }\n                        },\n                        \"clickTrackingParams\" : \"CLIDEP6YBBgNIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n                        \"createPlaylistServiceEndpoint\" : {\n                          \"params\" : \"CAQ%3D\",\n                          \"videoIds\" : [\n                            \"3jS_yEK8qVI\"\n                          ]\n                        }\n                      },\n                      \"listType\" : \"PLAYLIST_EDIT_LIST_TYPE_QUEUE\",\n                      \"videoIds\" : [\n                        \"3jS_yEK8qVI\"\n                      ],\n                      \"videoId\" : \"3jS_yEK8qVI\",\n                      \"openMiniplayer\" : true\n                    }\n                  }\n                ],\n                \"signal\" : \"CLIENT_SIGNAL\"\n              }\n            },\n            \"trackingParams\" : \"CLIDEP6YBBgNIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n            \"icon\" : {\n              \"iconType\" : \"ADD_TO_QUEUE_TAIL\"\n            },\n            \"text\" : {\n              \"runs\" : [\n                {\n                  \"text\" : \"Ajouter à la file d\'attente\"\n                }\n              ]\n            }\n          }\n        },\n        {\n          \"menuServiceItemRenderer\" : {\n            \"serviceEndpoint\" : {\n              \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\",\n              \"commandMetadata\" : {\n                \"webCommandMetadata\" : {\n                  \"sendPost\" : true,\n                  \"apiUrl\" : \"\\/youtubei\\/v1\\/share\\/get_share_panel\"\n                }\n              },\n              \"shareEntityServiceEndpoint\" : {\n                \"serializedShareEntity\" : \"CgszalNfeUVLOHFWSQ%3D%3D\",\n                \"commands\" : [\n                  {\n                    \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\",\n                    \"openPopupAction\" : {\n                      \"popupType\" : \"DIALOG\",\n                      \"popup\" : {\n                        \"unifiedSharePanelRenderer\" : {\n                          \"trackingParams\" : \"CLEDEI5iIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n                          \"showLoadingSpinner\" : true\n                        }\n                      },\n                      \"beReused\" : true\n                    }\n                  }\n                ]\n              }\n            },\n            \"trackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\",\n            \"icon\" : {\n              \"iconType\" : \"SHARE\"\n            },\n            \"hasSeparator\" : true,\n            \"text\" : {\n              \"runs\" : [\n                {\n                  \"text\" : \"Partager\"\n                }\n              ]\n            }\n          }\n        }\n      ],\n      \"trackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\"\n    }\n  },\n  \"detailedMetadataSnippets\" : [\n    {\n      \"snippetText\" : {\n        \"runs\" : [\n          {\n            \"text\" : \"J\'ai créé l\'escape game la plus dangereuse du monde et j\'ai mis mes abonnés au défi de s\'échapper pour gagner un prix ...\"\n          }\n        ]\n      },\n      \"snippetHoverText\" : {\n        \"runs\" : [\n          {\n            \"text\" : \"Issu de la description de la vidéo\"\n          }\n        ]\n      },\n      \"maxOneLine\" : false\n    }\n  ],\n  \"viewCountText\" : {\n    \"simpleText\" : \"208 643 518 vues\"\n  },\n  \"lengthText\" : {\n    \"accessibility\" : {\n      \"accessibilityData\" : {\n        \"label\" : \"8 minutes et 1 seconde\"\n      }\n    },\n    \"simpleText\" : \"8:01\"\n  },\n  \"publishedTimeText\" : {\n    \"simpleText\" : \"il y a 1 an\"\n  },\n  \"thumbnail\" : {\n    \"thumbnails\" : [\n      {\n        \"width\" : 360,\n        \"url\" : \"https:\\/\\/i.ytimg.com\\/vi\\/3jS_yEK8qVI\\/hq720.jpg?sqp=-oaymwEjCOgCEMoBSFryq4qpAxUIARUAAAAAGAElAADIQj0AgKJDeAE=&rs=AOn4CLBp_YwbHiu2aX7HXo1C-0jv6O6r5w\",\n        \"height\" : 202\n      },\n      {\n        \"width\" : 720,\n        \"url\" : \"https:\\/\\/i.ytimg.com\\/vi\\/3jS_yEK8qVI\\/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLAHLYZq8GDP1f8DUrYH6NUvnsdXsg\",\n        \"height\" : 404\n      }\n    ]\n  },\n  \"thumbnailOverlays\" : [\n    {\n      \"thumbnailOverlayTimeStatusRenderer\" : {\n        \"style\" : \"DEFAULT\",\n        \"text\" : {\n          \"simpleText\" : \"8:01\",\n          \"accessibility\" : {\n            \"accessibilityData\" : {\n              \"label\" : \"8 minutes et 1 seconde\"\n            }\n          }\n        }\n      }\n    },\n    {\n      \"thumbnailOverlayToggleButtonRenderer\" : {\n        \"untoggledAccessibility\" : {\n          \"accessibilityData\" : {\n            \"label\" : \"À regarder plus tard\"\n          }\n        },\n        \"toggledTooltip\" : \"Ajoutée\",\n        \"toggledServiceEndpoint\" : {\n          \"clickTrackingParams\" : \"CLADEPnnAxgDIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n          \"playlistEditEndpoint\" : {\n            \"actions\" : [\n              {\n                \"action\" : \"ACTION_REMOVE_VIDEO_BY_VIDEO_ID\",\n                \"removedVideoId\" : \"3jS_yEK8qVI\"\n              }\n            ],\n            \"playlistId\" : \"WL\"\n          },\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\\/edit_playlist\",\n              \"sendPost\" : true\n            }\n          }\n        },\n        \"untoggledServiceEndpoint\" : {\n          \"clickTrackingParams\" : \"CLADEPnnAxgDIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n          \"playlistEditEndpoint\" : {\n            \"actions\" : [\n              {\n                \"action\" : \"ACTION_ADD_VIDEO\",\n                \"addedVideoId\" : \"3jS_yEK8qVI\"\n              }\n            ],\n            \"playlistId\" : \"WL\"\n          },\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"sendPost\" : true,\n              \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\\/edit_playlist\"\n            }\n          }\n        },\n        \"untoggledIcon\" : {\n          \"iconType\" : \"WATCH_LATER\"\n        },\n        \"untoggledTooltip\" : \"À regarder plus tard\",\n        \"isToggled\" : false,\n        \"trackingParams\" : \"CLADEPnnAxgDIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n        \"toggledIcon\" : {\n          \"iconType\" : \"CHECK\"\n        },\n        \"toggledAccessibility\" : {\n          \"accessibilityData\" : {\n            \"label\" : \"Ajoutée\"\n          }\n        }\n      }\n    },\n    {\n      \"thumbnailOverlayToggleButtonRenderer\" : {\n        \"untoggledAccessibility\" : {\n          \"accessibilityData\" : {\n            \"label\" : \"Ajouter à la file d\'attente\"\n          }\n        },\n        \"toggledTooltip\" : \"Ajoutée\",\n        \"untoggledServiceEndpoint\" : {\n          \"clickTrackingParams\" : \"CK8DEMfsBBgEIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n          \"signalServiceEndpoint\" : {\n            \"signal\" : \"CLIENT_SIGNAL\",\n            \"actions\" : [\n              {\n                \"clickTrackingParams\" : \"CK8DEMfsBBgEIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n                \"addToPlaylistCommand\" : {\n                  \"onCreateListCommand\" : {\n                    \"clickTrackingParams\" : \"CK8DEMfsBBgEIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n                    \"commandMetadata\" : {\n                      \"webCommandMetadata\" : {\n                        \"sendPost\" : true,\n                        \"apiUrl\" : \"\\/youtubei\\/v1\\/playlist\\/create\"\n                      }\n                    },\n                    \"createPlaylistServiceEndpoint\" : {\n                      \"params\" : \"CAQ%3D\",\n                      \"videoIds\" : [\n                        \"3jS_yEK8qVI\"\n                      ]\n                    }\n                  },\n                  \"videoId\" : \"3jS_yEK8qVI\",\n                  \"videoIds\" : [\n                    \"3jS_yEK8qVI\"\n                  ],\n                  \"listType\" : \"PLAYLIST_EDIT_LIST_TYPE_QUEUE\",\n                  \"openMiniplayer\" : true\n                }\n              }\n            ]\n          },\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"sendPost\" : true\n            }\n          }\n        },\n        \"untoggledIcon\" : {\n          \"iconType\" : \"ADD_TO_QUEUE_TAIL\"\n        },\n        \"untoggledTooltip\" : \"Ajouter à la file d\'attente\",\n        \"toggledAccessibility\" : {\n          \"accessibilityData\" : {\n            \"label\" : \"Ajoutée\"\n          }\n        },\n        \"trackingParams\" : \"CK8DEMfsBBgEIhMIssCBqtLP_wIVyo58Ch0ezgEN\",\n        \"toggledIcon\" : {\n          \"iconType\" : \"PLAYLIST_ADD_CHECK\"\n        }\n      }\n    },\n    {\n      \"thumbnailOverlayNowPlayingRenderer\" : {\n        \"text\" : {\n          \"runs\" : [\n            {\n              \"text\" : \"En cours de lecture\"\n            }\n          ]\n        }\n      }\n    },\n    {\n      \"thumbnailOverlayLoadingPreviewRenderer\" : {\n        \"text\" : {\n          \"runs\" : [\n            {\n              \"text\" : \"Maintenez la souris sur la vidéo pour lancer la lecture\"\n            }\n          ]\n        }\n      }\n    }\n  ],\n  \"ownerBadges\" : [\n    {\n      \"metadataBadgeRenderer\" : {\n        \"trackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0=\",\n        \"icon\" : {\n          \"iconType\" : \"CHECK_CIRCLE_THICK\"\n        },\n        \"accessibilityData\" : {\n          \"label\" : \"Validé\"\n        },\n        \"tooltip\" : \"Validé\",\n        \"style\" : \"BADGE_STYLE_TYPE_VERIFIED\"\n      }\n    }\n  ],\n  \"navigationEndpoint\" : {\n    \"watchEndpoint\" : {\n      \"watchEndpointSupportedOnesieConfig\" : {\n        \"html5PlaybackOnesieConfig\" : {\n          \"commonConfig\" : {\n            \"url\" : \"https:\\/\\/rr2---sn-1gi7znek.googlevideo.com\\/initplayback?source=youtube&oeis=1&c=WEB&oad=3200&ovd=3200&oaad=11000&oavd=11000&ocs=700&oewis=1&oputc=1&ofpcc=1&beids=24350017&msp=1&odepv=1&id=de34bfc842bca952&ip=31.10.173.100&initcwndbps=2717500&mt=1687187839&oweuc=\"\n          }\n        }\n      },\n      \"params\" : \"qgMHbXJiZWFzdLoDCgjl9snI0qmv1X66AwsI5Njrn46BjMCiAboDCwja9I-99omIpPIBugMKCJn6tpX03JywGLoDCgikvJm-yILox2O6AwoI1o64qYaxwKNjugMLCMj2nISkiNKElgG6AwsIhKCniuKXnfexAboDCgjnt4f9hoXtnxS6AwoI4fGTnMmC961iugMKCP6h54KOgqX4S7oDCwjKm56kgsmo34ABugMLCPGglob-hMCw1QG6AwoIirX_iJDI6_ouugMLCP225f7A9NydsgG6AwsIqKDOqvnD07uwAboDCwja9I-99omIpPIBugMLCLWJrseqzpnYngG6AwoIq4qFgfSHhrEZugMLCIyNiOuUlovC_QG6AwoIw4npurXjwLsnugMKCIWX3YL_9d_4broDCwjdluydmIOzsNwBugMLCJGgn-isv6eS4QG6AwoI_qHngo6CpfhLugMLCNfgvPHnxvDLmgG6AwoIjIGhofbV8NBvugMKCOHxk5zJgvetYroDCgiS3Nr4rOvC73y6AwoIobTxk8XSuO9NugMKCJHCxtHz8bP7KLoDCgikvJm-yILox2O6AwsIvoy6ma3iu_yxAboDCwig2a-4pP_-jegBugMLCJiDxevNy4771AG6AwoImcDpmYzo8r1jugMKCOnz_NmT15jfSLoDCgiZ-raV9NycsBi6AwoI0PX1-bbN9uUZugMLCIaHy8KK17-D5QG6AwoI57eH_YaF7Z8UugMLCKm5j7KanJ2p2gG6AwoI1o64qYaxwKNjugMKCN-Nwu6or5-qdboDCwid1ePT4a2bkL4BugMLCITS0tDIhbLz8QG6AwsIvsSMn9b-6YyNAboDCgih08rjhe-agV26AwsIxarHz6uImtjKAboDCginp6fXmKCV8mC6AwsIyPachKSI0oSWAboDCwi34v2nkKTZob4BugMLCJCqyZ3NiI-jsgG6AwoI1Mzpoqz2-59GugMLCISx3omQtMPpjQG6AwsIqKDOqvnD07uwAboDCwi1ia7Hqs6Z2J4BugMKCKuKhYH0h4axGboDCwiMjYjrlJaLwv0BugMKCMOJ6bq148C7J7oDCgiFl92C__Xf-G66AwsI3ZbsnZiDs7DcAboDCwiRoJ_orL-nkuEBugMKCP6h54KOgqX4S7oDCgjHtYSMwPr19QO6AwoIsb2N85q23LhqugMKCJy7mvj39KaGH7oDCwiontW13sfx9tEBugMKCNfIyei069vND7oDCwiku7_ig4fHhs0BugMLCLq0xPG_jIfEigG6AwsIw5Lo_Nq6upLQAboDCgjK1Zrmssb_thu6AwoI2dn8v5ew5YhDugMKCOi75pC53emZWboDCgjrtZjI5s_ozky6AwsIlei0-raC95GfAfIDBQ0coj8-ggQCEAE%3D\",\n      \"videoId\" : \"3jS_yEK8qVI\",\n      \"playerParams\" : \"ygUHbXJiZWFzdA%3D%3D\"\n    },\n    \"clickTrackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ0yBnNlYXJjaFIHbXJiZWFzdJoBAxD0JA==\",\n    \"commandMetadata\" : {\n      \"webCommandMetadata\" : {\n        \"url\" : \"\\/watch?v=3jS_yEK8qVI&pp=ygUHbXJiZWFzdA%3D%3D\",\n        \"webPageType\" : \"WEB_PAGE_TYPE_WATCH\",\n        \"rootVe\" : 3832\n      }\n    }\n  },\n  \"showActionMenu\" : false,\n  \"title\" : {\n    \"accessibility\" : {\n      \"accessibilityData\" : {\n        \"label\" : \"L\'Escape Game Le Plus Dangereux Au Monde de MrBeast il y a 1 an 8 minutes et 1 seconde 208 643 518 vues\"\n      }\n    },\n    \"runs\" : [\n      {\n        \"text\" : \"L\'Escape Game Le Plus Dangereux Au Monde\"\n      }\n    ]\n  },\n  \"trackingParams\" : \"CK4DENwwGAIiEwiywIGq0s__AhXKjnwKHR7OAQ1A0tLylYT5r5reAQ==\"\n}
            """
        
        let testChannel = """
            {\n  \"subscriptionButton\" : {\n    \"subscribed\" : false\n  },\n  \"trackingParams\" : \"CP0DENowGAAiEwjn3JeF1s__AhWA0REIHSetAjU=\",\n  \"shortBylineText\" : {\n    \"runs\" : [\n      {\n        \"text\" : \"MrBeast\",\n        \"navigationEndpoint\" : {\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"webPageType\" : \"WEB_PAGE_TYPE_CHANNEL\",\n              \"rootVe\" : 3611,\n              \"url\" : \"\\/@MrBeast\",\n              \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\"\n            }\n          },\n          \"clickTrackingParams\" : \"CP0DENowGAAiEwjn3JeF1s__AhWA0REIHSetAjU=\",\n          \"browseEndpoint\" : {\n            \"canonicalBaseUrl\" : \"\\/@MrBeast\",\n            \"browseId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\"\n          }\n        }\n      }\n    ]\n  },\n  \"ownerBadges\" : [\n    {\n      \"metadataBadgeRenderer\" : {\n        \"accessibilityData\" : {\n          \"label\" : \"Validé\"\n        },\n        \"style\" : \"BADGE_STYLE_TYPE_VERIFIED\",\n        \"trackingParams\" : \"CP0DENowGAAiEwjn3JeF1s__AhWA0REIHSetAjU=\",\n        \"icon\" : {\n          \"iconType\" : \"CHECK_CIRCLE_THICK\"\n        },\n        \"tooltip\" : \"Validé\"\n      }\n    }\n  ],\n  \"longBylineText\" : {\n    \"runs\" : [\n      {\n        \"text\" : \"MrBeast\",\n        \"navigationEndpoint\" : {\n          \"browseEndpoint\" : {\n            \"canonicalBaseUrl\" : \"\\/@MrBeast\",\n            \"browseId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\"\n          },\n          \"clickTrackingParams\" : \"CP0DENowGAAiEwjn3JeF1s__AhWA0REIHSetAjU=\",\n          \"commandMetadata\" : {\n            \"webCommandMetadata\" : {\n              \"webPageType\" : \"WEB_PAGE_TYPE_CHANNEL\",\n              \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\",\n              \"rootVe\" : 3611,\n              \"url\" : \"\\/@MrBeast\"\n            }\n          }\n        }\n      }\n    ]\n  },\n  \"navigationEndpoint\" : {\n    \"commandMetadata\" : {\n      \"webCommandMetadata\" : {\n        \"webPageType\" : \"WEB_PAGE_TYPE_CHANNEL\",\n        \"apiUrl\" : \"\\/youtubei\\/v1\\/browse\",\n        \"rootVe\" : 3611,\n        \"url\" : \"\\/@MrBeast\"\n      }\n    },\n    \"clickTrackingParams\" : \"CP0DENowGAAiEwjn3JeF1s__AhWA0REIHSetAjU=\",\n    \"browseEndpoint\" : {\n      \"canonicalBaseUrl\" : \"\\/@MrBeast\",\n      \"browseId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\"\n    }\n  },\n  \"subscriberCountText\" : {\n    \"simpleText\" : \"@MrBeast\"\n  },\n  \"videoCountText\" : {\n    \"simpleText\" : \"161 M d’abonnés\",\n    \"accessibility\" : {\n      \"accessibilityData\" : {\n        \"label\" : \"161 millions d’abonnés\"\n      }\n    }\n  },\n  \"title\" : {\n    \"simpleText\" : \"MrBeast\"\n  },\n  \"thumbnail\" : {\n    \"thumbnails\" : [\n      {\n        \"width\" : 88,\n        \"url\" : \"\\/\\/yt3.googleusercontent.com\\/ytc\\/AGIKgqNRr7IEdQ7TplsO8BG-KjG19aCcCpVjiV9l36-9lQ=s88-c-k-c0x00ffffff-no-rj-mo\",\n        \"height\" : 88\n      },\n      {\n        \"width\" : 176,\n        \"url\" : \"\\/\\/yt3.googleusercontent.com\\/ytc\\/AGIKgqNRr7IEdQ7TplsO8BG-KjG19aCcCpVjiV9l36-9lQ=s176-c-k-c0x00ffffff-no-rj-mo\",\n        \"height\" : 176\n      }\n    ]\n  },\n  \"channelId\" : \"UCX6OQ3DkcsbYNE6H8uQQuVA\",\n  \"subscribeButton\" : {\n    \"buttonRenderer\" : {\n      \"style\" : \"STYLE_DESTRUCTIVE\",\n      \"navigationEndpoint\" : {\n        \"clickTrackingParams\" : \"CP4DEPBbIhMI59yXhdbP_wIVgNERCB0nrQI1\",\n        \"commandMetadata\" : {\n          \"webCommandMetadata\" : {\n            \"rootVe\" : 83769,\n            \"url\" : \"https:\\/\\/accounts.google.com\\/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26app%3Ddesktop%26hl%3Dfr%26next%3D%252Fresults%253Fsearch_query%253Dmrbeast%26continue_action%3DQUFFLUhqbllpVXFqOXRQUE1mOG91Z204Rzl2bVl3WjJOQXxBQ3Jtc0trRFJPOGlWaVlpTXRXVFI2cXliMjh4cDBUdWN1RUZnNWhKTjd1Snc2NE5mdmU1UzJYRldzWmhxbkdxdnlGdHBNWXJocEJYbG1CcGIwdDFaMHpaVkE4dzdKVk9RRjlGbHdkZWZjY2ZKSGlMRVBKNy1mQkVrWDVNamFhR2ZzekY2RXN2blgzLW9XQldsSVVaajZDMGh3UW5OVnpJNFE1cUJIUEdYblg3R21ZOG44dU1VdFZkTDVvLTZxOWVUM29HN3RaV2JZdnA&hl=fr\",\n            \"webPageType\" : \"WEB_PAGE_TYPE_UNKNOWN\"\n          }\n        },\n        \"signInEndpoint\" : {\n          \"nextEndpoint\" : {\n            \"clickTrackingParams\" : \"CP4DEPBbIhMI59yXhdbP_wIVgNERCB0nrQI1\",\n            \"searchEndpoint\" : {\n              \"query\" : \"mrbeast\"\n            },\n            \"commandMetadata\" : {\n              \"webCommandMetadata\" : {\n                \"webPageType\" : \"WEB_PAGE_TYPE_SEARCH\",\n                \"url\" : \"\\/results?search_query=mrbeast\",\n                \"rootVe\" : 4724\n              }\n            }\n          },\n          \"continueAction\" : \"QUFFLUhqbllpVXFqOXRQUE1mOG91Z204Rzl2bVl3WjJOQXxBQ3Jtc0trRFJPOGlWaVlpTXRXVFI2cXliMjh4cDBUdWN1RUZnNWhKTjd1Snc2NE5mdmU1UzJYRldzWmhxbkdxdnlGdHBNWXJocEJYbG1CcGIwdDFaMHpaVkE4dzdKVk9RRjlGbHdkZWZjY2ZKSGlMRVBKNy1mQkVrWDVNamFhR2ZzekY2RXN2blgzLW9XQldsSVVaajZDMGh3UW5OVnpJNFE1cUJIUEdYblg3R21ZOG44dU1VdFZkTDVvLTZxOWVUM29HN3RaV2JZdnA\"\n        }\n      },\n      \"trackingParams\" : \"CP4DEPBbIhMI59yXhdbP_wIVgNERCB0nrQI1\",\n      \"text\" : {\n        \"runs\" : [\n          {\n            \"text\" : \"S\'abonner\"\n          }\n        ]\n      },\n      \"size\" : \"SIZE_DEFAULT\",\n      \"isDisabled\" : false\n    }\n  },\n  \"descriptionSnippet\" : {\n    \"runs\" : [\n      {\n        \"text\" : \"SUBSCRIBE FOR A COOKIE! Accomplishments - Raised $20000000 To Plant 20000000 Trees - Given millions to charity ...\"\n      }\n    ]\n  }\n}
            """
        let testPlaylist = """
        {"playlistId":"PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","title":{"simpleText":"MrBeast Video Playlist"},"publishedTimeText": {"simpleText": "Mise à jour hier"},"thumbnails":[{"thumbnails":[{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCKgBEF5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDLCwZyZYIwScbdC5NMt6fWWiq6_A","width":168,"height":94},{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCMQBEG5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDWxQsTW09o1SIm4R7lNXynSai_MQ","width":196,"height":110},{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCPYBEIoBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLA56RCY3GarwNq-FbJImHoKH3ASmQ","width":246,"height":138},{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCNACELwBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLCYL9AEl5xWqrQ5oNNFywEj5Emnrw","width":336,"height":188}]},{"thumbnails":[{"url":"https://i.ytimg.com/vi/WcwGleN38zE/default.jpg","width":43,"height":20}]},{"thumbnails":[{"url":"https://i.ytimg.com/vi/fMfipiV_17o/default.jpg","width":43,"height":20}]},{"thumbnails":[{"url":"https://i.ytimg.com/vi/9bqk6ZUsKyA/default.jpg","width":43,"height":20}]},{"thumbnails":[{"url":"https://i.ytimg.com/vi/DuQbOQwVaNE/default.jpg","width":43,"height":20}]}],"videoCount":"206","navigationEndpoint":{"clickTrackingParams":"CMoDENswGAMiEwiZwdbHys__AhU0R3oFHVnpAeIyBnNlYXJjaA==","commandMetadata":{"webCommandMetadata":{"url":"/watch?v=TQHEJj68Jew&list=PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","webPageType":"WEB_PAGE_TYPE_WATCH","rootVe":3832}},"watchEndpoint":{"videoId":"TQHEJj68Jew","playlistId":"PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","params":"OAI%3D","loggingContext":{"vssLoggingContext":{"serializedContextData":"GiJQTEotcU9ETklVRUV0UGRLWk5MZmJ4N0pPdVJBX0pqVXhJ"}},"watchEndpointSupportedOnesieConfig":{"html5PlaybackOnesieConfig":{"commonConfig":{"url":"https://rr3---sn-1gi7znes.googlevideo.com/initplayback?source=youtube&oeis=1&c=WEB&oad=3200&ovd=3200&oaad=11000&oavd=11000&ocs=700&oewis=1&oputc=1&ofpcc=1&siu=1&msp=1&odepv=1&id=4d01c4263ebc25ec&ip=31.10.173.100&initcwndbps=3026250&mt=1687186168&oweuc="}}}}},"viewPlaylistText":{"runs":[{"text":"Afficher la playlist complète","navigationEndpoint":{"clickTrackingParams":"CMoDENswGAMiEwiZwdbHys__AhU0R3oFHVnpAeIyBnNlYXJjaA==","commandMetadata":{"webCommandMetadata":{"url":"/playlist?list=PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","webPageType":"WEB_PAGE_TYPE_PLAYLIST","rootVe":5754,"apiUrl":"/youtubei/v1/browse"}},"browseEndpoint":{"browseId":"VLPLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI"}}}]},"shortBylineText":{"runs":[{"text":"anjobanjo","navigationEndpoint":{"clickTrackingParams":"CMoDENswGAMiEwiZwdbHys__AhU0R3oFHVnpAeIyBnNlYXJjaA==","commandMetadata":{"webCommandMetadata":{"url":"/@ajdm168","webPageType":"WEB_PAGE_TYPE_CHANNEL","rootVe":3611,"apiUrl":"/youtubei/v1/browse"}},"browseEndpoint":{"browseId":"UCz-K9goyvbPIZq29lLJvrSA","canonicalBaseUrl":"/@ajdm168"}}}]},"videos":[{"childVideoRenderer":{"title":{"simpleText":"I Got Hunted By A Real Bounty Hunter"},"navigationEndpoint":{"clickTrackingParams":"CMoDENswGAMiEwiZwdbHys__AhU0R3oFHVnpAeIyBnNlYXJjaA==","commandMetadata":{"webCommandMetadata":{"url":"/watch?v=TQHEJj68Jew&list=PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","webPageType":"WEB_PAGE_TYPE_WATCH","rootVe":3832}},"watchEndpoint":{"videoId":"TQHEJj68Jew","playlistId":"PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","loggingContext":{"vssLoggingContext":{"serializedContextData":"GiJQTEotcU9ETklVRUV0UGRLWk5MZmJ4N0pPdVJBX0pqVXhJ"}},"watchEndpointSupportedOnesieConfig":{"html5PlaybackOnesieConfig":{"commonConfig":{"url":"https://rr3---sn-1gi7znes.googlevideo.com/initplayback?source=youtube&oeis=1&c=WEB&oad=3200&ovd=3200&oaad=11000&oavd=11000&ocs=700&oewis=1&oputc=1&ofpcc=1&siu=1&msp=1&odepv=1&id=4d01c4263ebc25ec&ip=31.10.173.100&initcwndbps=3026250&mt=1687186168&oweuc="}}}}},"lengthText":{"accessibility":{"accessibilityData":{"label":"14 minutes et 21 secondes"}},"simpleText":"14:21"},"videoId":"TQHEJj68Jew"}},{"childVideoRenderer":{"title":{"simpleText":"Extreme $100,000 Game of Tag!"},"navigationEndpoint":{"clickTrackingParams":"CMoDENswGAMiEwiZwdbHys__AhU0R3oFHVnpAeIyBnNlYXJjaA==","commandMetadata":{"webCommandMetadata":{"url":"/watch?v=WcwGleN38zE&list=PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","webPageType":"WEB_PAGE_TYPE_WATCH","rootVe":3832}},"watchEndpoint":{"videoId":"WcwGleN38zE","playlistId":"PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI","loggingContext":{"vssLoggingContext":{"serializedContextData":"GiJQTEotcU9ETklVRUV0UGRLWk5MZmJ4N0pPdVJBX0pqVXhJ"}},"watchEndpointSupportedOnesieConfig":{"html5PlaybackOnesieConfig":{"commonConfig":{"url":"https://rr1---sn-1gi7znes.googlevideo.com/initplayback?source=youtube&oeis=1&c=WEB&oad=3200&ovd=3200&oaad=11000&oavd=11000&ocs=700&oewis=1&oputc=1&ofpcc=1&siu=1&msp=1&odepv=1&id=59cc0695e377f331&ip=31.10.173.100&initcwndbps=3026250&mt=1687186168&oweuc="}}}}},"lengthText":{"accessibility":{"accessibilityData":{"label":"16 minutes et 54 secondes"}},"simpleText":"16:54"},"videoId":"WcwGleN38zE"}}],"videoCountText":{"runs":[{"text":"206"},{"text":" vidéos"}]},"trackingParams":"CMoDENswGAMiEwiZwdbHys__AhU0R3oFHVnpAeI=","thumbnailText":{"runs":[{"text":"206","bold":true},{"text":" vidéos"}]},"longBylineText":{"runs":[{"text":"anjobanjo","navigationEndpoint":{"clickTrackingParams":"CMoDENswGAMiEwiZwdbHys__AhU0R3oFHVnpAeIyBnNlYXJjaA==","commandMetadata":{"webCommandMetadata":{"url":"/@ajdm168","webPageType":"WEB_PAGE_TYPE_CHANNEL","rootVe":3611,"apiUrl":"/youtubei/v1/browse"}},"browseEndpoint":{"browseId":"UCz-K9goyvbPIZq29lLJvrSA","canonicalBaseUrl":"/@ajdm168"}}}]},"thumbnailRenderer":{"playlistVideoThumbnailRenderer":{"thumbnail":{"thumbnails":[{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCKgBEF5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDLCwZyZYIwScbdC5NMt6fWWiq6_A","width":168,"height":94},{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCMQBEG5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDWxQsTW09o1SIm4R7lNXynSai_MQ","width":196,"height":110},{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCPYBEIoBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLA56RCY3GarwNq-FbJImHoKH3ASmQ","width":246,"height":138},{"url":"https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCNACELwBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLCYL9AEl5xWqrQ5oNNFywEj5Emnrw","width":336,"height":188}],"sampledThumbnailColor":{"red":89,"green":66,"blue":66}},"trackingParams":"CMsDEMvsCSITCJnB1sfKz_8CFTRHegUdWekB4g=="}},"thumbnailOverlays":[{"thumbnailOverlayBottomPanelRenderer":{"text":{"simpleText":"206 vidéos"},"icon":{"iconType":"PLAYLISTS"}}},{"thumbnailOverlayHoverTextRenderer":{"text":{"runs":[{"text":"Tout lire"}]},"icon":{"iconType":"PLAY_ALL"}}},{"thumbnailOverlayNowPlayingRenderer":{"text":{"runs":[{"text":"En cours de lecture"}]}}}]}
        """
        
        /// Testing video decoding
        let testVideoShouldBe = YTVideo(
            videoId: "3jS_yEK8qVI",
            title: "L'Escape Game Le Plus Dangereux Au Monde",
            channel: .init(channelId: "UCX6OQ3DkcsbYNE6H8uQQuVA", name: "MrBeast"),
            viewCount: "208 M de vues",
            timePosted: "il y a 1 an",
            timeLength: "8:01",
            thumbnails: [
                .init(width: 360, height: 202, url: URL(string:     "https://i.ytimg.com/vi/3jS_yEK8qVI/hq720.jpg?sqp=-oaymwEjCOgCEMoBSFryq4qpAxUIARUAAAAAGAElAADIQj0AgKJDeAE=&rs=AOn4CLBp_YwbHiu2aX7HXo1C-0jv6O6r5w")!),
                .init(width: 720, height: 404, url: URL(string: "https://i.ytimg.com/vi/3jS_yEK8qVI/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLAHLYZq8GDP1f8DUrYH6NUvnsdXsg")!)
            ]
        )
        
        if let testVideoData = testVideo.data(using: .utf8, allowLossyConversion: false) {
            let testResponseVideo = YTVideo.decodeJSON(data: testVideoData)
            XCTAssertEqual(testResponseVideo, testVideoShouldBe, TEST_NAME + "Checking video decoding")
        } else {
            XCTFail(TEST_NAME + "Couldn't encode testVideoData to Data.")
        }
        
        /// Testing channel decoding
        let testChannelShouldBe = YTChannel(
            name: "MrBeast",
            channelId: "UCX6OQ3DkcsbYNE6H8uQQuVA",
            handle: "@MrBeast",
            thumbnails: [
                .init(width: 88, height: 88, url: URL(string: "https://yt3.googleusercontent.com/ytc/AGIKgqNRr7IEdQ7TplsO8BG-KjG19aCcCpVjiV9l36-9lQ=s88-c-k-c0x00ffffff-no-rj-mo")!),
                .init(width: 176, height: 176, url: URL(string: "https://yt3.googleusercontent.com/ytc/AGIKgqNRr7IEdQ7TplsO8BG-KjG19aCcCpVjiV9l36-9lQ=s176-c-k-c0x00ffffff-no-rj-mo")!)
            ],
            subscriberCount: "161 M d’abonnés",
            badges: [
                "BADGE_STYLE_TYPE_VERIFIED"
            ]
        )
        
        if let testChannelData = testChannel.data(using: .utf8, allowLossyConversion: false) {
            let testResponseChannel = YTChannel.decodeJSON(data: testChannelData)
            XCTAssertEqual(testResponseChannel, testChannelShouldBe, TEST_NAME + "Checking channel decoding")
        } else {
            XCTFail(TEST_NAME + "Couldn't encode testChannelData to Data.")
        }
        
        /// Testing playlist decoding
        let testPlaylistShouldBe = YTPlaylist(
            playlistId: "VLPLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI",
            title: "MrBeast Video Playlist",
            thumbnails: [
                .init(width: 168, height: 94, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCKgBEF5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDLCwZyZYIwScbdC5NMt6fWWiq6_A")!),
                .init(width: 196, height: 110, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCMQBEG5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDWxQsTW09o1SIm4R7lNXynSai_MQ")!),
                .init(width: 246, height: 138, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCPYBEIoBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLA56RCY3GarwNq-FbJImHoKH3ASmQ")!),
                .init(width: 336, height: 188, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCNACELwBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLCYL9AEl5xWqrQ5oNNFywEj5Emnrw")!)
            ],
            videoCount: "206 vidéos",
            channel: .init(channelId: "UCz-K9goyvbPIZq29lLJvrSA", name: "anjobanjo"),
            timePosted: "Mise à jour hier",
            frontVideos: [
                .init(videoId: "TQHEJj68Jew", title: "I Got Hunted By A Real Bounty Hunter", viewCount: "", timeLength: "14:21"),
                .init(videoId: "WcwGleN38zE", title: "Extreme $100,000 Game of Tag!", viewCount: "", timeLength: "16:54")
            ]
        )
        
        if let testPlaylistData = testPlaylist.data(using: .utf8, allowLossyConversion: false) {
            let testResponsePlaylist = YTPlaylist.decodeJSON(data: testPlaylistData)
            XCTAssertEqual(testResponsePlaylist, testPlaylistShouldBe, TEST_NAME + "Checking playlist decoding")
        } else {
            XCTFail(TEST_NAME + "Couldn't encode testPlaylistData to Data.")
        }
    }
    
    func testSearchResponseContinuation() async {
        let TEST_NAME = "Test: testSearchResponseContinuation() -> "
        
        let (requestResult, _) = await SearchResponse.sendRequest(youtubeModel: YTM, data: [.query: "fred again"])
        guard let continuationToken = requestResult?.continuationToken else { XCTFail(TEST_NAME + "continuationToken is not defined"); return }
        guard let visitorData = requestResult?.visitorData else { XCTFail(TEST_NAME + "visitorData is not defined"); return }
        if let _ = requestResult {
            let (continuationResult, _) = await SearchResponse.Continuation.sendRequest(youtubeModel: YTM, data: [
                .continuation: continuationToken,
                .visitorData: visitorData
            ])
            if let continuationResult = continuationResult {
                XCTAssertNotEqual(continuationResult.continuationToken, "", TEST_NAME + "Checking continuationToken for SearchResponse.Contination.")
                XCTAssertNotEqual(continuationResult.results.count, 0, TEST_NAME + "Checking if continuation results aren't empty.")
            } else {
                XCTFail(TEST_NAME + "Failed to get continuationResult (SearchResponse.Continuation request failed).")
            }
        } else {
            XCTFail(TEST_NAME + "Failed to get requestResult (SearchResponse request failed).")
        }
    }
    
    func testVideoInfosResponse() async {
        let TEST_NAME = "Test: testVideoInfosResponse() -> "
        let video = YTVideo(videoId: "90RLzVUuXe4")
        
        let (requestResult, requestError) = await video.fetchStreamingInfos(youtubeModel: YTM)
                
        guard let requestResult = requestResult else { XCTFail(TEST_NAME + "requestResult is not defined, error: \(String(describing: requestError))."); return }
        
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
    }
    
    func testVideoInfosWithDownloadFormatsResponse() async {
        let TEST_NAME = "Test: testVideoInfosWithDownloadFormatsResponse() -> "
        
        VideoInfosWithDownloadFormatsResponse.removePlayersFromDisk()
        
        for video in [YTVideo(videoId: "3ryID_SwU5E"), YTVideo(videoId: "xUdZhqe2n7w")] as [YTVideo] {
            
            let (requestResult, requestError) = await video.fetchStreamingInfosWithDownloadFormats(youtubeModel: YTM)
            
            guard let requestResult = requestResult else { XCTFail(TEST_NAME + "requestResult is not defined, error: \(String(describing: requestError))."); return }
            
            XCTAssertNotEqual(requestResult.downloadFormats.count, 0, TEST_NAME + "Checking if requestResult.downloadFormats is empty")
            XCTAssertNotEqual(requestResult.defaultFormats.count, 0, TEST_NAME + "Checking if requestResult.defaultFormats is empty")
            XCTAssertNotEqual(requestResult.videoInfos.streamingURL, nil, TEST_NAME + "Checking if requestResult.videoInfos.streamingURL is empty")
        }
    }

    func testAutoCompletionResponse() async {
        YTM.selectedLocale = "en-US"
        
        let TEST_NAME = "Test: testAutoCompletionResponse() -> "
        
        let query: String = "mrbe"
        
        let (requestResult, _) = await AutoCompletionResponse.sendRequest(youtubeModel: YTM, data: [.query: query])
        
        guard let requestResult = requestResult else { XCTFail(TEST_NAME + "requestResult is not defined."); return }
        
        XCTAssertEqual(requestResult.initialQuery, query, TEST_NAME + "Checking if query and initialQuery are equal")
        XCTAssertNotEqual(requestResult.autoCompletionEntries.count, 0, TEST_NAME + "Checking if requestResult.autoCompletionEntries is empty")
    }
    
    func testChannelInfosResponse() async {
        let TEST_NAME = "Test: testChannelInfosResponse() -> "
        
        let (videoResult, videoResultError) = await VideoInfosResponse.sendRequest(youtubeModel: YTM, data: [.query: "bvUNXch3rdI"]) /// T-Series' video because they have continuation in every category
        
        guard let videoResult = videoResult else { XCTFail(TEST_NAME + "Couldn't get video infos, error: \(String(describing: videoResultError))"); return }
        
        guard let channel = videoResult.channel, channel.channelId != "" else { XCTFail(TEST_NAME + "The channel in the retrieved video is not defined (structure nil or channelId empty)."); return }
        
        let (mainRequestResult, mainRequestResultError) = await channel.fetchInfos(youtubeModel: YTM)
        
        guard let mainRequestResult = mainRequestResult else { XCTFail(TEST_NAME + "Couldn't get channel base infos, error: \(String(describing: mainRequestResultError))"); return }
        
        XCTAssertNotNil(mainRequestResult.videosCount, TEST_NAME + "Checking if mainRequestResult.videosCount is not nil")
        
        /// Testing ChannelContent fetching, Videos, Shorts, Directs and Playlists
        
        ///Videos
        let (videoRequestResult, videoRequestResultError) = await mainRequestResult.getChannelContent(type: .videos, youtubeModel: YTM)
        
        guard let videoRequestResult = videoRequestResult else { XCTFail(TEST_NAME + "Couldn't get channel Videos special content, error: \(String(describing: videoRequestResultError))"); return }
        
        XCTAssertEqual(videoRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if videoRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(videoRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if videoRequestResult.channelId is equal to videoResult.channel.channelId")
        
        /// Test continuation
        let (videoRequestContinuationResult, videoRequestContinuationResultError) = await videoRequestResult.getChannelContentContinuation(ChannelInfosResponse.Videos.self, youtubeModel: YTM)
        
        guard let _ = videoRequestContinuationResult else { XCTFail(TEST_NAME + "Couldn't get continuation for Videos special content, error: \(String(describing: videoRequestContinuationResultError))"); return }
        
        /// Shorts
        let (shortsRequestResult, shortsRequestResultError) = await mainRequestResult.getChannelContent(type: .shorts, youtubeModel: YTM)
        
        guard let shortsRequestResult = shortsRequestResult else { XCTFail(TEST_NAME + "Couldn't get channel Shorts special content, error: \(String(describing: shortsRequestResultError))"); return }
        
        XCTAssertEqual(shortsRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if shortsRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(shortsRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if shortsRequestResult.channelId is equal to videoResult.channel.channelId")
                
        /// Test continuation
        let (shortsRequestContinuationResult, shortsRequestContinuationResultError) = await shortsRequestResult.getChannelContentContinuation(ChannelInfosResponse.Shorts.self, youtubeModel: YTM)
        
        guard let _ = shortsRequestContinuationResult else { XCTFail(TEST_NAME + "Couldn't get continuation for Shorts special content, error: \(String(describing: shortsRequestContinuationResultError))"); return }
        
        /// Directs
        let (directsRequestResult, directsRequestResultError) = await mainRequestResult.getChannelContent(type: .directs, youtubeModel: YTM)
        
        guard let directsRequestResult = directsRequestResult else { XCTFail(TEST_NAME + "Couldn't get channel Directs special content, error: \(String(describing: directsRequestResultError))"); return }
        
        XCTAssertEqual(directsRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if directsRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(directsRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if directsRequestResult.channelId is equal to videoResult.channel.channelId")
        
        /// Test continuation
        let (directsRequestContinuationResult, directsRequestContinuationResultError) = await directsRequestResult.getChannelContentContinuation(ChannelInfosResponse.Directs.self, youtubeModel: YTM)
        
        guard let _ = directsRequestContinuationResult else { XCTFail(TEST_NAME + "Couldn't get continuation for Directs special content, error: \(String(describing: directsRequestContinuationResultError))"); return }
        
        /// Playlists
        let (playlistsRequestResult, playlistsRequestResultError) = await mainRequestResult.getChannelContent(type: .playlists, youtubeModel: YTM)
        
        guard let playlistsRequestResult = playlistsRequestResult else { XCTFail(TEST_NAME + "Couldn't get channel Directs special content, error: \(String(describing: playlistsRequestResultError))"); return }
        
        XCTAssertEqual(playlistsRequestResult.name, videoResult.channel?.name, TEST_NAME + "Checking if playlistsRequestResult.name is equal to videoResult.channel.name")
        XCTAssertEqual(playlistsRequestResult.channelId, videoResult.channel?.channelId, TEST_NAME + "Checking if playlistsRequestResult.channelId is equal to videoResult.channel.channelId")
        
        /// Test continuation
        let (playlistRequestContinuationResult, playlistRequestContinuationResultError) = await playlistsRequestResult.getChannelContentContinuation(ChannelInfosResponse.Playlists.self, youtubeModel: YTM)
        
        guard let _ = playlistRequestContinuationResult else { XCTFail(TEST_NAME + "Couldn't get continuation for Playlists special content, error: \(String(describing: playlistRequestContinuationResultError))"); return }
    }
    
    func testGetPlaylistInfos() async {
        let TEST_NAME = "Test: testGetPlaylistInfos() -> "
        
        let playlist = YTPlaylist(playlistId: "VLPLw-VjHDlEOgs658kAHR_LAaILBXb-s6Q5")
        
        let (playlistInfosResult, playlistInfosError) = await playlist.fetchVideos(youtubeModel: YTM)
        
        guard var playlistInfosResult = playlistInfosResult else { XCTFail(TEST_NAME + "Checking if playlistInfosResult is defined (error: \(String(describing: playlistInfosError)))."); return }
        
        let (playlistContinuation, playlistContinuationError) = await playlistInfosResult.fetchContinuation(youtubeModel: YTM)
        
        guard let playlistContinuation = playlistContinuation else { XCTFail(TEST_NAME + "Checking if the continuation is defined (error: \(String(describing: playlistContinuationError))."); return } // Could fail if the 
        
        let videoCount = playlistInfosResult.results.count + playlistContinuation.results.count
        playlistInfosResult.mergeWithContinuation(playlistContinuation)
        XCTAssertEqual(playlistInfosResult.results.count, videoCount, TEST_NAME + "Checking if the merge operation was successful. (videos count)")
        XCTAssertEqual(playlistInfosResult.continuationToken, playlistContinuation.continuationToken, TEST_NAME + "Checking if the merge operation was successful. (continuation token)")
    }
    
    func testHomeResponse() async {
        let TEST_NAME = "Test: testHomeResponse() -> "
            
        let (homeMenuResult, homeMenuResultError) = await HomeScreenResponse.sendRequest(youtubeModel: YTM, data: [:])
        guard var homeMenuResult = homeMenuResult else { XCTFail(TEST_NAME + "Checking if homeMenuResult is defined (error: \(String(describing: homeMenuResultError)))."); return }
        guard homeMenuResult.continuationToken != nil else {
            // Could fail because sometimes YouTube gives an empty page telling you to start browsing. We check this case here.
            if !(homeMenuResult.results.count == 0 && homeMenuResult.visitorData != nil) {
                XCTFail(TEST_NAME + "Checking if homeMenuResult.continuationToken is defined (error: \(String(describing: homeMenuResultError))).");
            }
            return
        }
        
        XCTAssertNotNil(homeMenuResult.visitorData, TEST_NAME + "Checking if homeMenuResult.visitorData is defined (error: \(String(describing: homeMenuResultError))).")
        
        let (homeMenuContinuationResult, homeMenuContinuationError) = await homeMenuResult.fetchContinuation(youtubeModel: YTM)
                
        guard let homeMenuContinuationResult = homeMenuContinuationResult else { XCTFail(TEST_NAME + "Checking if homeMenuContinuationResult is defined (error: \(String(describing: homeMenuContinuationError)))."); return }
        guard homeMenuContinuationResult.continuationToken != nil else { XCTFail(TEST_NAME + "Checking if homeMenuContinuationResult.continuationToken is defined (error: \(String(describing: homeMenuContinuationError)))."); return }
        
        let videosCount = homeMenuResult.results.count + homeMenuContinuationResult.results.count
        
        homeMenuResult.mergeContinuation(homeMenuContinuationResult)
        
        XCTAssertEqual(homeMenuResult.results.count, videosCount, TEST_NAME + "Checking if the merge operation was successful (videos count).")
        XCTAssertEqual(homeMenuResult.continuationToken, homeMenuContinuationResult.continuationToken, TEST_NAME + "Checking if the merge operation was successful (continuationToken).")
    }
    
    /// The following tests can't be done without some Account's cookies
    func testAccountInfos() async {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testAccountInfos() -> "
        YTM.cookies = cookies
        
        let (response, error) = await AccountInfosResponse.sendRequest(youtubeModel: YTM, data: [:])
        
        guard let response = response else { XCTFail(TEST_NAME + "Checking if AccountInfosResponse is defined (error: \(String(describing: error)))."); return  }
        
        guard !response.isDisconnected else { XCTFail(TEST_NAME + "Checking if the cookies are valid."); return }
        
        /// Could potentially fail if the cookies' account does not have a channel.
        XCTAssertNotNil(response.channelHandle, TEST_NAME + "Checking if the channelHandle has been extracted (may have failed because your account does not have a channel).")
        XCTAssertNotNil(response.name, TEST_NAME + "Checking if the name of the account has been extracted.")
        XCTAssertNotEqual(response.avatar.count, 0, TEST_NAME + "Checking if the avatar of the account has been extracted.")
    }
    
    func testAccountLibrary() async {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testAccountLibrary() -> "
        YTM.cookies = cookies
        
        let (response, error) = await AccountLibraryResponse.sendRequest(youtubeModel: YTM, data: [:])
        
        guard let response = response else { XCTFail(TEST_NAME + "Checking if AccountLibraryResponse is defined (error: \(String(describing: error)))."); return }
        
        guard !response.isDisconnected else { XCTFail(TEST_NAME + "Checking if cookies were defined"); return }
        
        //XCTAssertNotEqual(response.accountStats.count, 0, TEST_NAME + "Checking if account's stats have been extracted.") // has been removed by YouTube
        XCTAssertNotNil(response.history, TEST_NAME + "Checking if history has been extracted.")
        XCTAssertNotNil(response.likes, TEST_NAME + "Checking if likes has been extracted.")
        XCTAssertNotNil(response.watchLater, TEST_NAME + "Checking if watchLater has been extracted.")
        XCTAssertNotEqual(response.playlists.count, 0, TEST_NAME + "Checking if account's playlists have been extracted.")
    }
    
    func testPlaylistActions() async {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testPlaylistActions() -> "
        YTM.cookies = cookies
        
        let newPlaylistName = "YouTubeKitTest-\(UUID().uuidString)"
        
        let firstVideoToAddId = "peIBCNTY8hA"
        let secondVideoToAddId = "3ryID_SwU5E"
        let thirdVideoToAddId = "OlWdMCVtKJw"
        
        // Playlist creation part
        let (creationResponse, creationError) = await CreatePlaylistResponse.sendRequest(youtubeModel: YTM, data: [.query : newPlaylistName, .params: YTPrivacy.private.rawValue, .movingVideoId: firstVideoToAddId])
        
        guard let creationResponse = creationResponse else { XCTFail(TEST_NAME + "Checking if CreatePlaylistResponse is defined (error: \(String(describing: creationError)))."); return }
        
        guard !creationResponse.isDisconnected else { XCTFail(TEST_NAME + "Checking if cookies were defined"); return }
        
        guard var createdPlaylistId = creationResponse.createdPlaylistId, let playlistCreatorId = creationResponse.playlistCreatorId else { XCTFail(TEST_NAME + "Checking if the playlist has been created."); return }
        
        XCTAssertNotNil(creationResponse.playlistCreatorId, TEST_NAME + "Checking if the playlist's creator has been extracted.")
        
        // Let the playlist be updated in YouTube's servers
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let firstVideo = YTVideo(videoId: firstVideoToAddId)
        let (allPlaylistResponse, allPlaylistsError) = await firstVideo.fetchAllPossibleHostPlaylists(youtubeModel: YTM)
        
        guard let allPlaylistResponse = allPlaylistResponse else { XCTFail(TEST_NAME + "Checking if allPlaylistResponse is defined (error: \(String(describing: allPlaylistsError)))."); return }
        
        guard let createdPlaylistResult = allPlaylistResponse.playlistsAndStatus.first(where: {$0.playlist.playlistId.contains(createdPlaylistId) || createdPlaylistId.contains($0.playlist.playlistId)} /* avoid VL prefix notation bug*/) else { XCTFail(TEST_NAME + "Checking if the created playlist is listed among the other playlists."); return }
        
        XCTAssert(createdPlaylistResult.isVideoPresentInside, TEST_NAME + "Checking if video is present inside the new playlist.")
        XCTAssertEqual(createdPlaylistResult.playlist.privacy, YTPrivacy.private, TEST_NAME + "Checking if the privacy is correctly extracted.")
        
        if createdPlaylistId.hasPrefix("VL") { // We need to remove the VL in order to make the following requests
            createdPlaylistId = String(createdPlaylistId.dropFirst(2))
        }
        
        // Video adding part
        let (addVideoResponse, addVideoError) = await AddVideoToPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoToAddId, .browseId: createdPlaylistId])
        
        guard let addVideoResponse = addVideoResponse else { XCTFail(TEST_NAME + "Checking if AddVideoToPlaylistResponse is defined (error: \(String(describing: addVideoError)))."); return }
        
        guard !addVideoResponse.isDisconnected, addVideoResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(addVideoResponse.addedVideoId, secondVideoToAddId, TEST_NAME + "Checking if the video has been added.")
        guard let secondVideoIdInPlaylist = addVideoResponse.addedVideoIdInPlaylist else { XCTFail(TEST_NAME + "Checking if the videoIdInPlaylist has been extracted."); return }
        XCTAssertEqual(addVideoResponse.playlistId, "VL" + createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        XCTAssertEqual(addVideoResponse.playlistCreatorId, playlistCreatorId, TEST_NAME + "Checking if the video has been added with the right account.")
        // Adding it a second time
        let (addVideoResponse2, addVideoError2) = await AddVideoToPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: thirdVideoToAddId, .browseId: createdPlaylistId])
        
        guard let addVideoResponse2 = addVideoResponse2 else { XCTFail(TEST_NAME + "Checking if AddVideoToPlaylistResponse is defined (error: \(String(describing: addVideoError2)))."); return }
        
        guard !addVideoResponse2.isDisconnected, addVideoResponse2.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(addVideoResponse2.addedVideoId, thirdVideoToAddId, TEST_NAME + "Checking if the video has been added.")
        guard let thirdVideoIdInPlaylist = addVideoResponse2.addedVideoIdInPlaylist else { XCTFail(TEST_NAME + "Checking if the videoIdInPlaylist has been extracted."); return }
        XCTAssertEqual(addVideoResponse2.playlistId, "VL" + createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        XCTAssertEqual(addVideoResponse2.playlistCreatorId, playlistCreatorId, TEST_NAME + "Checking if the video has been added with the right account.")
        // Adding a third video
        let (addVideoResponse3, addVideoError3) = await AddVideoToPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoToAddId, .browseId: createdPlaylistId])
        
        guard let addVideoResponse3 = addVideoResponse3 else { XCTFail(TEST_NAME + "Checking if AddVideoToPlaylistResponse is defined (error: \(String(describing: addVideoError3)))."); return }
        
        guard !addVideoResponse3.isDisconnected, addVideoResponse3.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(addVideoResponse3.addedVideoId, secondVideoToAddId, TEST_NAME + "Checking if the video has been added.")
        guard let lastVideoIdInPlaylist = addVideoResponse3.addedVideoIdInPlaylist else { XCTFail(TEST_NAME + "Checking if the videoIdInPlaylist has been extracted."); return }
        XCTAssertEqual(addVideoResponse3.playlistId, "VL" + createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        XCTAssertEqual(addVideoResponse3.playlistCreatorId, playlistCreatorId, TEST_NAME + "Checking if the video has been added with the right account.")
        
        // Moving the last video to the third position
        let (moveVideoResponse, moveVideoError) = await MoveVideoInPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: lastVideoIdInPlaylist, .videoBeforeId: secondVideoIdInPlaylist, .browseId: createdPlaylistId])
        
        guard let moveVideoResponse = moveVideoResponse else { XCTFail(TEST_NAME + "Checking if MoveVideoInPlaylistResponse is defined (error: \(String(describing: moveVideoError)))."); return }

        guard !moveVideoResponse.isDisconnected, moveVideoResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(moveVideoResponse.playlistId, createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        // Moving the second video to the first position
        let (moveVideoResponse2, moveVideoError2) = await MoveVideoInPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoIdInPlaylist, .browseId: createdPlaylistId])
        
        guard let moveVideoResponse2 = moveVideoResponse2 else { XCTFail(TEST_NAME + "Checking if MoveVideoInPlaylistResponse is defined (error: \(String(describing: moveVideoError2)))."); return }

        guard !moveVideoResponse2.isDisconnected, moveVideoResponse2.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        XCTAssertEqual(moveVideoResponse2.playlistId, createdPlaylistId, TEST_NAME + "Checking if the video has been added in the right playlist.")
        
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
        if !createdPlaylistId.hasPrefix("VL") { // We need to remove the VL in order to make the following requests
            createdPlaylistId = "VL" + createdPlaylistId
        }
        let (finalPlaylist, finalPlaylistError) = await PlaylistInfosResponse.sendRequest(youtubeModel: YTM, data: [.browseId: createdPlaylistId], useCookies: true)
        
        guard let finalPlaylist = finalPlaylist else { XCTFail(TEST_NAME + "Checking if PlaylistInfosResponse is defined (error: \(String(describing: finalPlaylistError)))."); return }

        guard finalPlaylist.results.filter({$0 as? YTVideo != nil}).map({($0 as! YTVideo).videoId}) == [secondVideoToAddId, firstVideoToAddId, secondVideoToAddId, thirdVideoToAddId] else { XCTFail(TEST_NAME + "Checking if all the addings and moves were correctly executed."); return }
        
        // Removing part
        if createdPlaylistId.hasPrefix("VL") { // We need to remove the VL in order to make the following requests
            createdPlaylistId = String(createdPlaylistId.dropFirst(2))
        }
        let (removeVideoResponse, removeVideoError) = await RemoveVideoFromPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: thirdVideoIdInPlaylist, .playlistEditToken: "CAFAAQ%3D%3D", .browseId: createdPlaylistId], useCookies: true) // playlistEditToken is hardcoded here, could lead to some error
        
        guard let removeVideoResponse = removeVideoResponse else { XCTFail(TEST_NAME + "Checking if RemoveVideoFromPlaylistResponse is defined (error: \(String(describing: removeVideoError)))."); return }
        
        guard !removeVideoResponse.isDisconnected, removeVideoResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        let (removeVideoResponse2, removeVideoError2) = await RemoveVideoByIdFromPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: secondVideoToAddId, .browseId: createdPlaylistId], useCookies: true)

        guard let removeVideoResponse2 = removeVideoResponse2 else { XCTFail(TEST_NAME + "Checking if RemoveVideoByIdFromPlaylistResponse is defined (error: \(String(describing: removeVideoError2)))."); return }
        
        guard !removeVideoResponse2.isDisconnected, removeVideoResponse2.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
        
        // Checking the playlist
        if !createdPlaylistId.hasPrefix("VL") { // We need to remove the VL in order to make the following requests
            createdPlaylistId = "VL" + createdPlaylistId
        }
        let (finalPlaylist2, finalPlaylistError2) = await PlaylistInfosResponse.sendRequest(youtubeModel: YTM, data: [.browseId: createdPlaylistId], useCookies: true)
        
        guard let finalPlaylist2 = finalPlaylist2 else { XCTFail(TEST_NAME + "Checking if PlaylistInfosResponse is defined (error: \(String(describing: finalPlaylistError2)))."); return }

        guard finalPlaylist2.results.filter({$0 as? YTVideo != nil}).map({($0 as! YTVideo).videoId}) == [firstVideoToAddId] else { XCTFail(TEST_NAME + "Checking if all the removing were correctly executed."); return }
        
        // Deleting the playlist
        
        if createdPlaylistId.hasPrefix("VL") { // We need to remove the VL in order to make the following requests
            createdPlaylistId = String(createdPlaylistId.dropFirst(2))
        }
        let (deletePlaylistResponse, deletePlaylistError) = await DeletePlaylistResponse.sendRequest(youtubeModel: YTM, data: [.browseId: createdPlaylistId])
        
        guard let deletePlaylistResponse = deletePlaylistResponse else { XCTFail(TEST_NAME + "Checking if y.sDeletePlaylistResponse is defined (error: \(String(describing: deletePlaylistError)))."); return }

        guard !deletePlaylistResponse.isDisconnected, deletePlaylistResponse.success else { XCTFail(TEST_NAME + "Checking if cookies were defined and that the request was successful."); return }
    }
    
    func testHistoryResponse() async {
        let TEST_NAME = "Test: testHistoryResponse() -> "
        guard cookies != "" else { return }
        YTM.cookies = cookies
        
        let (historyResponse, historyError) = await HistoryResponse.sendRequest(youtubeModel: YTM, data: [:], useCookies: true)
        
        guard let historyResponse = historyResponse else { XCTFail(TEST_NAME + "Checking if historyResponse is defined (error: \(String(describing: historyError)))."); return }
        
        XCTAssertNotNil(historyResponse.title, TEST_NAME + "Checking if historyResponse.title has been extracted.")
        XCTAssertNotEqual(historyResponse.videosAndTime.count, 0, TEST_NAME + "Checking if historyResponse.videosAndTime is not empty.")
        
        guard let firstVideoToken = historyResponse.videosAndTime.first?.videosArray.first?.suppressToken else { XCTFail(TEST_NAME + "Could not find a video with a suppressToken in the history"); return }
        
        let deleteFromHistoryError = await historyResponse.removeVideo(withSuppressToken: firstVideoToken, youtubeModel: YTM)
        
        XCTAssertNil(deleteFromHistoryError, TEST_NAME + "Error while trying to delete video from history: \(String(describing: deleteFromHistoryError))")
    }
    
    func testMoreVideoInfosResponse() async {
        let TEST_NAME = "Test: testMoreVideoInfosResponse() -> "
        YTM.cookies = cookies

        let video = YTVideo(videoId: "nVoMKVU1FAg")

        let (moreVideoInfosResponse, moreVideoInfosError) = await video.fetchMoreInfos(youtubeModel: YTM, useCookies: true)
        
        guard var moreVideoInfosResponse = moreVideoInfosResponse else { XCTFail(TEST_NAME + "Checking if moreVideoInfosResponse is defined, error -> \(String(describing: moreVideoInfosError))"); return }
        
        if cookies != "" {
            XCTAssertNotNil(moreVideoInfosResponse.authenticatedInfos, TEST_NAME + "Checking if the authenticationData has been extracted.")
            XCTAssertNotNil(moreVideoInfosResponse.authenticatedInfos?.likeStatus, TEST_NAME + "Checking if the authenticationData.likeStatus has been extracted.")
            XCTAssertNotNil(moreVideoInfosResponse.authenticatedInfos?.subscriptionStatus, TEST_NAME + "Checking if the authenticationData.subscriptionStatus has been extracted.") // Will fail if the account is the owner of the tested video.
        }
        
        XCTAssertNotNil(moreVideoInfosResponse.channel, TEST_NAME + "Checking if the channel has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.commentsCount, TEST_NAME + "Checking if the commentsCount has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.likesCount.defaultState, TEST_NAME + "Checking if the likesCount has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.recommendedVideosContinuationToken, TEST_NAME + "Checking if the recommendedVideosContinuationToken has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.timePosted.postedDate, TEST_NAME + "Checking if the timePosted.postedDate has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.timePosted.relativePostedDate, TEST_NAME + "Checking if the timePosted.relativePostedDate has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.videoDescription, TEST_NAME + "Checking if the videoDescription has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.videoTitle, TEST_NAME + "Checking if the videoTitle has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.viewsCount.fullViewsCount, TEST_NAME + "Checking if the viewsCount.fullViewsCount has been extracted.")
        XCTAssertNotNil(moreVideoInfosResponse.viewsCount.shortViewsCount, TEST_NAME + "Checking if the viewsCount.shortViewsCount has been extracted.")
        
        /// Fetch the continuation of the recommendedVideos
        let (recommendedVideosContinuationResponse, recommendedVideosContinuationError) = await moreVideoInfosResponse.getRecommendedVideosContination(youtubeModel: YTM)
        
        guard let recommendedVideosContinuationResponse = recommendedVideosContinuationResponse else { XCTFail(TEST_NAME + "Checking if recommendedVideosResponse is defined, error -> \(String(describing: recommendedVideosContinuationError))"); return }
        
        guard !(moreVideoInfosResponse.recommendedVideos.isEmpty && recommendedVideosContinuationResponse.results.isEmpty) else { XCTFail(TEST_NAME + "No recommanded videos in the first place nor with the continuationResponse, error -> \(String(describing: recommendedVideosContinuationError))"); return}
        
        XCTAssertNotEqual(recommendedVideosContinuationResponse.results.count, 0, TEST_NAME + "Checking if results for continuation have been extracted.")
        XCTAssertNotNil(recommendedVideosContinuationResponse.continuationToken, TEST_NAME + "Checking if continuationToken has been extracted.")
        let initialRecommendedVideosCount = moreVideoInfosResponse.recommendedVideos.count
        
        moreVideoInfosResponse.mergeRecommendedVideosContination(recommendedVideosContinuationResponse)
        XCTAssertEqual(initialRecommendedVideosCount + recommendedVideosContinuationResponse.results.count, moreVideoInfosResponse.recommendedVideos.count, TEST_NAME + "Checking if the merge operation was successful (arrays merging).")
        XCTAssertEqual(moreVideoInfosResponse.recommendedVideosContinuationToken, recommendedVideosContinuationResponse.continuationToken, TEST_NAME + "Checking if the merge operation was successful (continuationToken overwriting).")
    }
    
    func testLikeRequests() async {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testLikeRequests() -> "
        YTM.cookies = cookies
        
        let video = YTVideo(videoId: "JdFRjsEZrmU")
        
        let likeStatus: MoreVideoInfosResponse.AuthenticatedData.LikeStatus? = await getCurrentLikeStatus()
        
        guard let likeStatus = likeStatus else { XCTFail(TEST_NAME + "Checking if likeStatus is defined"); return}
    
        switch likeStatus {
        case .liked:
            await dislikeVideo()
            try? await Task.sleep(nanoseconds: 1_000_000_000) // introduce some delay to avoid a block from YouTube.
            await removelikeVideo()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await likeVideo()
        case .disliked:
            await removelikeVideo()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await likeVideo()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await dislikeVideo()
        case .nothing:
            await likeVideo()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await dislikeVideo()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await removelikeVideo()
        }
        
        func getCurrentLikeStatus() async -> MoreVideoInfosResponse.AuthenticatedData.LikeStatus? {
            let (currentStatusResponse, currentStatusError) = await video.fetchMoreInfos(youtubeModel: YTM, useCookies: true)
            
            guard let currentStatusResponse = currentStatusResponse else { XCTFail(TEST_NAME + "Checking if currentStatusResponse is defined, error -> \(String(describing: currentStatusError))"); return nil}
            
            return currentStatusResponse.authenticatedInfos?.likeStatus
        }
        
        func dislikeVideo() async {
            let dislikeVideoError = await video.dislikeVideo(youtubeModel: YTM)
            
            XCTAssertNil(dislikeVideoError, TEST_NAME + "Checking if dislikeVideoResponse is defined, error -> \(String(describing: dislikeVideoError))")
                        
            let localLikeStatus = await getCurrentLikeStatus()
            guard localLikeStatus == .disliked else { XCTFail(TEST_NAME + "Checking if localLikeStatus is disliked"); return }
        }
        
        func likeVideo() async {
            let likeVideoError = await video.likeVideo(youtubeModel: YTM)
            
            XCTAssertNil(likeVideoError, TEST_NAME + "Checking if likeVideoResponse is defined, error -> \(String(describing: likeVideoError))")
                        
            let localLikeStatus = await getCurrentLikeStatus()
            guard localLikeStatus == .liked else { XCTFail(TEST_NAME + "Checking if localLikeStatus is liked"); return }
        }
        
        func removelikeVideo() async {
            let removeLikeFromVideoError = await video.removeLikeFromVideo(youtubeModel: YTM)
            XCTAssertNil(removeLikeFromVideoError, TEST_NAME + "Checking if removeLikeFromVideoResponse is defined, error -> \(String(describing: removeLikeFromVideoError))")
                        
            let localLikeStatus = await getCurrentLikeStatus()
            guard localLikeStatus == .nothing else { XCTFail(TEST_NAME + "Checking if localLikeStatus is nothing"); return }
        }
    }
    
    func testSubscriptionRequests() async {
        guard cookies != "" else { return }
        let TEST_NAME = "Test: testSubscriptionRequests() -> "
        YTM.cookies = cookies
        
        let video = YTVideo(videoId: "-K8nQk-iZzs")
        
        let videoInfosResponse = await getSubscriptionStatus()
        guard let currentStatus = videoInfosResponse?.authenticatedInfos?.subscriptionStatus, let channel = videoInfosResponse?.channel else { XCTFail(TEST_NAME + "Checking if subscriptionStatus and channelId are defined."); return }
        
        if currentStatus {
            await unsubscribeToChannel()
            await subscribeToChannel()
        } else {
            await subscribeToChannel()
            await unsubscribeToChannel()
        }
        
        func getSubscriptionStatus() async -> MoreVideoInfosResponse? {
            let (videoResponse, videoError) = await video.fetchMoreInfos(youtubeModel: YTM, useCookies: true)
            
            guard let videoResponse = videoResponse else { XCTFail(TEST_NAME + "Checking if videoResponse is defined, error -> \(String(describing: videoError))"); return nil }
            XCTAssertNotNil(videoResponse.authenticatedInfos, TEST_NAME + "Checking if request has been authenticated.")
            return videoResponse
        }
        
        func subscribeToChannel() async {
            let (channelError) = await channel.subscribe(youtubeModel: YTM)
            XCTAssertNil(channelError, TEST_NAME + "Checking if channelError is nil, error -> \(String(describing: channelError))")
        }
        
        func unsubscribeToChannel() async {
            let (channelError) = await channel.unsubscribe(youtubeModel: YTM)
            XCTAssertNil(channelError, TEST_NAME + "Checking if channelError is nil, error -> \(String(describing: channelError))")
        }
    }
}
