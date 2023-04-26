import SwiftUI

Color.green


public func getResultsForSearch(query: String, result: @escaping ([YTBasePageOutputWithIndex]?, ErrorMessage?) -> Void) {
     getHeaders(action: .search) { headers in
        if let headers = headers {
            print("Setting up request")
            let request = setHeadersAgentFor(content: headers, query: query)
            self.firstTask = URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("Error while executing HTTP request \(error.localizedDescription)")
                    result(nil, ErrorMessage(code: 500, message: "Error while executing the request."))
                } else {
                    if let data = data {
                        var serverRequest = URLRequest(url: ServerURLs.getResultsForSearch.rawValue.toURL())
                        //                var serverRequest = URLRequest(url: URL(string: "https://webhook.site/afcfcb46-f423-4635-b049-7092f10294c0")!)
                        serverRequest.httpMethod = "POST"
                        serverRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        serverRequest.compressAndLoadBody(data: data)
                        let dataSt = String(decoding: data, as: UTF8.self)
                        serverRequest.setValue(String(describing: dataSt.hmac()), forHTTPHeaderField: "HASH")
                        serverRequest.setValue(APIM.APIKey, forHTTPHeaderField: "APIKEY")
                        serverRequest.setValue(query, forHTTPHeaderField: "SEARCH")
                        self.serverTask = URLSession.shared.dataTask(with: serverRequest) { data1, _, _ in
                            if let data1 = data1 {
//                                let dataStr = String(decoding: data1, as: UTF8.self)
                                do {
                                    let decodedData = try JSONDecoder().decode([YTBasePageOutputWithIndex].self, from: data1)
//                                    print(decodedData)
//                                    result(decodedData.filter({!($0.videoID == nil && $0.title == nil && $0.continuationToken == nil && $0.visitorData == nil)}))
                                    result(decodedData.filter({
                                        if $0.type == .video {
                                            return $0.videoID != nil
                                        } else {
                                            return true
                                        }
                                    }), nil)
                                } catch {
                                    print(error)
                                    do {
                                        let decodedData = try JSONDecoder().decode(YTBasePageOutputWithIndex.self, from: data1)
//                                        print(decodedData)
                                        if decodedData.code == 900 {
                                            APIM.deleteKeyAndInvalid()
                                        }
                                        result(nil, ErrorMessage(code: 401, message: "Key is not valid."))
                                    } catch {
                                        print(error)
                                        result(nil, ErrorMessage(code: 501, message: "Error while decoding data."))
                                    }
                                }
                            } else {
                                print("Data couldn't be fetched1")
                                result(nil, ErrorMessage(code: 502, message: "Error while decoding data."))
                            }
                        }
                        self.serverTask?.resume()
                    } else {
                        print("Data couldn't be fetched")
                        result(nil, ErrorMessage(code: 503, message: "Error while decoding data."))
                    }
                }
            }
            self.firstTask?.resume()
        } else {
            print("Couldn't fetch headers")
            result(nil, ErrorMessage(code: 504, message: "Error fetching headers."))
        }
    }
}
