//
//  SearchView.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 - 2026 Antoine Bollengier. All rights reserved.
//  

import SwiftUI

struct SwiftUIView: View {
    private var YTM = YouTubeModel()
    @State private var text: String = ""
    var body: some View {
        TextField("Search", text: $text)
        Button {
            SearchResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.query : text], result: { result in
                switch result {
                case .success(let response):
                    print("Got a response! \(String(describing: response))")
                case .failure(let error):
                    print("Failed to get a response: \(error.localizedDescription)")
                }
            })
            /// You can also use async await system or even using throws
            /*
            Task {
                let result = await SearchResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.query : text])
                // or
                let result = try await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query : text])
            }
            */
        } label: {
            Text("Search")
        }
    }
}

