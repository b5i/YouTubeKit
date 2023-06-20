import XCTest
@testable import YouTubeKit

final class YouTubeKitTests: XCTestCase {
    private let YTM = YouTubeModel()
    
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
        let decodedURLShouldBe = "https://raw.githubusercontent.com/b5i/antoinebollengier/main/YouTubeKitTests/CreateCustomHeadersGET.json?q=testquery%252F%2540&t=query%2540%252F"
        XCTAssertEqual(decodedURL, decodedURLShouldBe, TEST_NAME + "Checking equality of URLs.")
        
        /// Checking actual headers
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "*/*", TEST_NAME + "Checking equality of header \"Accept\".")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Encoding"), "gzip, deflate, br", TEST_NAME + "Checking equality of header \"Accept-Encoding\".")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "\(self.YTM.selectedLocale);q=0.9", TEST_NAME + "Checking equality of header \"Accept-Language\".")
        XCTAssertEqual(request.value(forHTTPHeaderField: "MyCustomHTTPHeader"), "Ahahahah", TEST_NAME + "Checking equality of header \"MyCustomHTTPHeader\".")
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
        let testVideoShouldBe = YTSearchResultType.Video(
            videoId: "3jS_yEK8qVI",
            title: "L'Escape Game Le Plus Dangereux Au Monde",
            channel: .init(name: "MrBeast", browseId: "UCX6OQ3DkcsbYNE6H8uQQuVA"),
            viewCount: "208 M de vues",
            timePosted: "il y a 1 an",
            timeLength: "8:01",
            thumbnails: [
                .init(width: 360, height: 202, url: URL(string:     "https://i.ytimg.com/vi/3jS_yEK8qVI/hq720.jpg?sqp=-oaymwEjCOgCEMoBSFryq4qpAxUIARUAAAAAGAElAADIQj0AgKJDeAE=&rs=AOn4CLBp_YwbHiu2aX7HXo1C-0jv6O6r5w")!),
                .init(width: 720, height: 404, url: URL(string: "https://i.ytimg.com/vi/3jS_yEK8qVI/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLAHLYZq8GDP1f8DUrYH6NUvnsdXsg")!)
            ]
        )
        
        if let testVideoData = testVideo.data(using: .utf8, allowLossyConversion: false) {
            let testResponseVideo = YTSearchResultType.Video.decodeJSON(data: testVideoData)
            XCTAssertEqual(testResponseVideo, testVideoShouldBe, TEST_NAME + "Checking video decoding")
        } else {
            XCTFail(TEST_NAME + "Couldn't encode testVideoData to Data.")
        }
        
        /// Testing channel decoding
        let testChannelShouldBe = YTSearchResultType.Channel(
            name: "MrBeast",
            browseId: "UCX6OQ3DkcsbYNE6H8uQQuVA",
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
            let testResponseChannel = YTSearchResultType.Channel.decodeJSON(data: testChannelData)
            XCTAssertEqual(testResponseChannel, testChannelShouldBe, TEST_NAME + "Checking channel decoding")
        } else {
            XCTFail(TEST_NAME + "Couldn't encode testChannelData to Data.")
        }
        
        /// Testing playlist decoding
        let testPlaylistShouldBe = YTSearchResultType.Playlist(
            playlistId: "PLJ-qODNIUEEtPdKZNLfbx7JOuRA_JjUxI",
            title: "MrBeast Video Playlist",
            thumbnails: [
                .init(width: 168, height: 94, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCKgBEF5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDLCwZyZYIwScbdC5NMt6fWWiq6_A")!),
                .init(width: 196, height: 110, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEWCMQBEG5IWvKriqkDCQgBFQAAiEIYAQ==&rs=AOn4CLDWxQsTW09o1SIm4R7lNXynSai_MQ")!),
                .init(width: 246, height: 138, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCPYBEIoBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLA56RCY3GarwNq-FbJImHoKH3ASmQ")!),
                .init(width: 336, height: 188, url: URL(string: "https://i.ytimg.com/vi/TQHEJj68Jew/hqdefault.jpg?sqp=-oaymwEXCNACELwBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLCYL9AEl5xWqrQ5oNNFywEj5Emnrw")!)
            ],
            videoCount: "206 vidéos",
            channel: .init(name: "anjobanjo", browseId: "UCz-K9goyvbPIZq29lLJvrSA"),
            timePosted: "Mise à jour hier",
            frontVideos: [
                .init(videoId: "TQHEJj68Jew", title: "I Got Hunted By A Real Bounty Hunter", viewCount: "", timeLength: "14:21"),
                .init(videoId: "WcwGleN38zE", title: "Extreme $100,000 Game of Tag!", viewCount: "", timeLength: "16:54")
            ]
        )
        
        if let testPlaylistData = testPlaylist.data(using: .utf8, allowLossyConversion: false) {
            let testResponsePlaylist = YTSearchResultType.Playlist.decodeJSON(data: testPlaylistData)
            XCTAssertEqual(testResponsePlaylist, testPlaylistShouldBe, TEST_NAME + "Checking playlist decoding")
        } else {
            XCTFail(TEST_NAME + "Couldn't encode testPlaylistData to Data.")
        }
    }
    
    func testSearchResponseContinuation() async {
        let TEST_NAME = "Test: testSearchResponseContinuation() -> "
        
        let (requestResult, _) = await SearchResponse.sendRequest(youtubeModel: YTM, data: [.query: "fred again"])
        XCTAssertNotEqual(requestResult?.continuationToken, "", TEST_NAME + "Checking if continuationToken is defined.")
        XCTAssertNotEqual(requestResult?.visitorData, "", TEST_NAME + "Checking if visitorData is defined.")
        if let requestResult = requestResult {
            let (continuationResult, _) = await SearchResponse.Continuation.sendRequest(youtubeModel: YTM, data: [
                .continuation: requestResult.continuationToken,
                .visitorData: requestResult.visitorData
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
        
        let (requestResult, _) = await VideoInfosResponse.sendRequest(youtubeModel: YTM, data: [.query: "90RLzVUuXe4"])
        
        guard let requestResult = requestResult else { XCTFail(TEST_NAME + "requestResult is not defined."); return }
        
        XCTAssertNotNil(requestResult.channel.name, TEST_NAME + "Checking if requestResult.channel.name is not nil.")
        XCTAssertNotNil(requestResult.channel.browseId, TEST_NAME + "Checking if requestResult.channel.browseId is not nil.")
        XCTAssertNotNil(requestResult.isLive, TEST_NAME + "Checking if requestResult.isLive is not nil.")
        XCTAssertNotEqual(requestResult.keywords.count, 0, TEST_NAME + "Checking if requestResult.channel.name is not nil.")
        XCTAssertNotNil(requestResult.streamingURL, TEST_NAME + "Checking if requestResult.streamingURL is not nil.")
        XCTAssertNotNil(requestResult.title, TEST_NAME + "Checking if requestResult.title is not nil.")
        XCTAssertNotNil(requestResult.videoDescription, TEST_NAME + "Checking if requestResult.videoDescription is not nil.")
        XCTAssertNotNil(requestResult.videoId, TEST_NAME + "Checking if requestResult.videoId is not nil.")
        XCTAssertNotNil(requestResult.videoURLsExpireAt, TEST_NAME + "Checking if requestResult.videoURLsExpireAt is not nil.")
        XCTAssertNotNil(requestResult.viewCount, TEST_NAME + "Checking if requestResult.viewCount is not nil.")
    }
}
