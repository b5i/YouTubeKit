# YouTubeKit

YouTubeKit is a powerful Swift package to make requests to the YouTube API without having any API key.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fb5i%2FYouTubeKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/b5i/YouTubeKit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fb5i%2FYouTubeKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/b5i/YouTubeKit)

## Installation: 

1. Install the package to your Xcode project:
  1. In the top menu go to File->Add Packages...
  2. Enter the link of this repository: https://github.com/b5i/YouTubeKit (you may have to connect Xcode to your github account).
  3. Click on `Add Package`.
2. Use it in your project by importing it: `import YouTubeKit`.

Please note that this is adapted from another iOS app and so is in constant developpement.

## Default requests:
Here is a list of the default requests supported by YouTubeKit, all the informations you can get are:

- [HomeScreenResponse](https://github.com/b5i/YouTubeKit/blob/8b418c4c59f68b3b1c00a71744e2626efef8f629/Sources/YouTubeKit/YouTubeResponseTypes/Home/HomeScreenResponse.swift#L11) -> get videos from the main page of YouTube, its [Continuation](https://github.com/b5i/YouTubeKit/blob/8b418c4c59f68b3b1c00a71744e2626efef8f629/Sources/YouTubeKit/YouTubeResponseTypes/Home/HomeScreenResponse.swift#L57) is also available.

- [SearchResponse](https://github.com/b5i/YouTubeKit/blob/55633edd56a5a0c2ec4d315422f2590d2348ae20/Sources/YouTubeKit/YouTubeResponseTypes/Search/SearchResponse.swift#LL11C46-L11C46) -> get results for a text query, its [Continuation](https://github.com/b5i/YouTubeKit/blob/55633edd56a5a0c2ec4d315422f2590d2348ae20/Sources/YouTubeKit/YouTubeResponseTypes/Search/SearchResponse.swift#L94) is also available.

- [SearchResponse.Restricted](https://github.com/b5i/YouTubeKit/blob/d5db7e61cf017af4969669cfee5c075e185a771a/Sources/YouTubeKit/YouTubeResponseTypes/Search/SearchResponse.swift#L94) -> get Creative Commons copyrighted results for a text query.

- [VideoInfosResponse](https://github.com/b5i/YouTubeKit/blob/1aed7cf4ef662b3ba689ce28f05a8b0f496ed7e6/Sources/YouTubeKit/YouTubeResponseTypes/VideoInfos/VideoInfosResponse.swift#L11) -> get the infos of a video by ID.

- [VideoInfosWithDownloadFormatsResponse](https://github.com/b5i/YouTubeKit/blob/3023f4468429f77d57f0e786f0c5b08b9a8dd51b/Sources/YouTubeKit/YouTubeResponseTypes/VideoInfos/VideoInfosWithDownloadFormatsResponse.swift#L18) -> get the infos of a video by ID and the DownloadFormats, consumes more bandwidth than [VideoInfosResponse](https://github.com/b5i/YouTubeKit/blob/1aed7cf4ef662b3ba689ce28f05a8b0f496ed7e6/Sources/YouTubeKit/YouTubeResponseTypes/VideoInfos/VideoInfosResponse.swift#L11) but has an array of DownloadFormat.

- [AutoCompletionResponse](https://github.com/b5i/YouTubeKit/blob/1458b48d66d7cfc3b095186ca7f1e5d561188506/Sources/YouTubeKit/YouTubeResponseTypes/AutoCompletion/AutoCompletionResponse.swift#L13) -> get autoCompletion suggestions from a text query.

- [ChannelInfosResponse](https://github.com/b5i/YouTubeKit/blob/be3ff98f57856ab8f75e00c07d8b49c2281004b3/Sources/YouTubeKit/YouTubeResponseTypes/ChannelInfos/ChannelInfosResponse.swift#L10C15-L10C35) -> get infos of a YouTube channel by its id.
    - Possiblity to fetch more infos about a channel like its [Videos](https://github.com/b5i/YouTubeKit/blob/be3ff98f57856ab8f75e00c07d8b49c2281004b3/Sources/YouTubeKit/YouTubeResponseTypes/ChannelInfos/ChannelInfosResponse.swift#L278), [Shorts](https://github.com/b5i/YouTubeKit/blob/be3ff98f57856ab8f75e00c07d8b49c2281004b3/Sources/YouTubeKit/YouTubeResponseTypes/ChannelInfos/ChannelInfosResponse.swift#L309), [Directs](https://github.com/b5i/YouTubeKit/blob/be3ff98f57856ab8f75e00c07d8b49c2281004b3/Sources/YouTubeKit/YouTubeResponseTypes/ChannelInfos/ChannelInfosResponse.swift#L340), [Playlists](https://github.com/b5i/YouTubeKit/blob/be3ff98f57856ab8f75e00c07d8b49c2281004b3/Sources/YouTubeKit/YouTubeResponseTypes/ChannelInfos/ChannelInfosResponse.swift#L371) and their continuation.
 
- [PlaylistInfosResponse](https://github.com/b5i/YouTubeKit/blob/721120db20cdd00cf6b586fb3accc02345cb205a/Sources/YouTubeKit/YouTubeResponseTypes/PlaylistInfos/PlaylistInfosResponse.swift#L11) -> get a playlist's informations and the videos it contains. Its [Continuation](https://github.com/b5i/YouTubeKit/blob/721120db20cdd00cf6b586fb3accc02345cb205a/Sources/YouTubeKit/YouTubeResponseTypes/PlaylistInfos/PlaylistInfosResponse.swift#L130) is also available. 

## Make requests:
Every possible request within YouTubeKit conforms to the protocol [YouTubeResponse](https://github.com/b5i/YouTubeKit/blob/c858d62d49946658df7c00f9380b04f3f78e32d0/Sources/YouTubeKit/YouTubeResponse.swift#L31), it contains a few useful methods: 
- `static var headersType` is a static variable indicating the type of headers used to make the request, its documentation indicates which parameter to provide in order to make the request work.
- `static func decodeData(data: Data) -> Self` is a static method used to decode some Data and give back in instance of the `YouTubeResponse`, if the Data does not represent a proper response it will return an empty response (only nils and empty arrays).
- `static func sendRequest()` is a static method that allows you to make request, by using async await system or closures. Its usage will be precised in the following tutorial.

With YouTubeKit you can make a large variety of requests to the YouTube API, new request types are added often and you can even create your own in [Custom requests/responses](#custom-requests-and-responses).

1. Make sure you have an instance of `YouTubeModel`, if not you can create one with
  ```swift
  let YTM = YouTubeModel()
  ```
2. Define the request's data parameters, to get the demanded headers you can look at the definition of your `YouTubeResponse.headersType` it should describe which data to send. 
   An example with a `SearchResponse`:
   
   a. Right click on the type of request and press `Jump to definition`, the `SearchResponse.headersType` is `HeaderTypes.search`.
   
   b. Its definition is
   ```swift
   /// Get search results.
   /// - Parameter query: Search query
   case search
   ```

   it means that you will have to provide a query for the request to work and give a relevant result.

   c. You will define the data parameters like this:
   ```swift
   let textQuery: String = "my super query"
   let dataParameters: [HeadersList.AddQueryInfo.ContentTypes : String] = [
       .query: textQuery
   ]
   ```

4. Execute the request with (e.g. a `SearchResponse` request)
  ```swift
  SearchResponse.sendRequest(youtubeModel: YTM, data: dataParameters, result: { result, error in
       /// Process here the result.
       print(result)

       /// If the result is nil you should obtain an error explaining why there is one.
       print(error)
  })
  ```
  you can also send the request without explicitly declaring `dataParameters` like this
  ```swift
  SearchResponse.sendRequest(youtubeModel: YTM, data: [.query: textQuery], result: { result, error in
       /// Process here the result.
       print(result)

       /// If the result is nil you should obtain an error explaining why there is one.
       print(error)
  })
  ```


## Custom requests and responses:
To create custom headers and so custom request/response function, you have to:
1. Append the function that is used to generate the `HeadersList` in `YouTubeModel.customHeadersFunctions`, e.g

```swift
let YTM = YouTubeModel()
let myCustomHeadersFunction: () -> HeadersList = {
    HeadersList(
        url: URL(string: "https://www.myrequesturl.com")!,
        method: .POST,
        headers: [
            .init(name: "Accept", content: "*/*"),
            .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
            .init(name: "Accept-Language", content: "\(YTM.selectedLocale);q=0.9"),
        ],
        addQueryAfterParts: [
            .init(index: 0, encode: true)
        ],
        httpBody: [
            "my query is: ",
            " and it is really cool!"
        ]
    )
}

YouTubeModel.shared.customHeadersFunctions["myHeadersID"] = myCustomHeadersFunction
```
2. Create the response that is conform to the YouTubeResponse protocol, e.g
```swift
/*
We imagine that the JSON is of the form:
{
  "name": "myName",
  "surname": "mySurname"
}
*/


/// Struct representing a getNameAndSurname response.
public struct NameAndSurnameResponse: YouTubeResponse {
    public static var headersType: HeaderTypes = .customHeaders("myHeadersID") //<- the myHeadersID has to be the same as the one you defined in step 1!
    
    /// String representing a name.
    public var name: String = ""
    
    /// String representing a surname.
    public var surname: String = ""
    
    public static func decodeData(data: Data) -> NameAndSurnameResponse {
        /// Initialize an empty response.
        var nameAndSurnameResponse = NameAndSurnameResponse()
        // Extracts the data of the JSON, can also be done using normal JSONDecoder().decode(NameAndSurnameResponse.self, data) by making NameAndSurnameResponse conform to Codable protocol as the JSON is not very complex here.
        
        let json = JSON(data)
        
        nameAndSurnameResponse.name = json["name"].stringValue
        nameAndSurnameResponse.surname = json["surname"].stringValue
        
        return nameAndSurnameResponse
    }
}
```
3. And to exectute it you just have to call `func sendRequest<ResponseType: YouTubeResponse>(
    responseType: ResponseType.Type,
    data: [HeadersList.AddQueryInfo.ContentTypes : String],
    result: @escaping (ResponseType?, Error?) -> ()
)`
e.g,
```swift
/// We continue with our example:
NameAndSurnameResponse.sendRequest(youtubeModel: YTM, data: [:], result: { result, error in
    /// Process here the result.
    print(result)
    
    /// If the result is nil you should obtain an error explaining why there is one.
    print(error)
})
```
Note: you would include in the request the parameters if needed like: query, browseId or anything like this to put in the body of the request to send.


## Troubleshooting: 
This category lists solutions to problems you might encounter with YouTubeKit.

### Connections problems
- ```Error Domain=NSURLErrorDomain Code=-1003 "A server with the specified hostname could not be found."```

  This issue can be resolved by enabling the `Outgoing Connections (Client)` in the `Signing & Capabilities` category of your project's target in Xcode.

- The download speed is very low when downloading an audio-only `DownloadFormat`: this issue can be resolved by adding the `range: bytes=0-(CONTENT_LENGHT_BYTES)` HTTP header to your `URLRequest` (e.g. `request.addValue("bytes=0-\(myDownloadFormat.contentLength ?? "")", forHTTPHeaderField: "range")`).


