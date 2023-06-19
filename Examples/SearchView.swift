//
//  SearchView.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 04.06.23.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import SwiftUI

struct SwiftUIView: View {
    private var YTM = YouTubeModel()
    @State private var text: String = ""
    var body: some View {
        TextField("Search", text: $text)
        Button {
            SearchResponse.sendRequest(youtubeModel: YTM, data: [.query : text], result: { result, error in
                print(result)
                print(error)
            })
        } label: {
            Text("Search")
        }
    }
}

