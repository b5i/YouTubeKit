# YouTubeKit

YouTubeKit is a powerful Swift package to make requests to the YouTube API without having any API key.


## Installation: 

1. Install the package to your Xcode project:
  1. In the top menu go to File->Add Packages...
  2. Enter the link of this repository: https://github.com/b5i/YouTubeKit (you may have to connect Xcode to your github account).
  3. Click on `Add Package`.
2. Use it in your project by importing it: `import YouTubeKit`.

Please note that this is adapted from another iOS app and so is in constant developpement.

## Custom requests/responses:
To create custom headers and so custom request/response function you have to:
1. Append the function that is used to generate the `HeadersList` in `YouTubeModel.customHeadersFunctions`, e.g

```swift
let myCustomHeadersFunction: () -> HeadersList = {
    HeadersList(
        url: URL(string: "https://www.myrequesturl.com")!,
        method: .POST,
        headers: [
            .init(name: "Accept", content: "*/*"),
            .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
            .init(name: "Accept-Language", content: "\(self.selectedLocale);q=0.9"),
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
    public static var headersType: HeaderTypes = .customHeader("myHeadersID") //<- the myHeadersID has to be the same as the one you defined in step 1!
    
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
sendRequest(responseType: NameAndSurnameResponse.self, data: [:], result: { result, error in
        print(result)
        print(error)
})
```
Note: you would include in the request the parameters if needed like: query, browseId or anything like this to put in the body of the request to send.
