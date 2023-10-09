//
//  ContentView.swift
//  Example
//
//  Created by Ryohei Kameyama on 2023/10/09.
//

import SwiftUI
import Zoomable

struct ContentView: View {
    var body: some View {
        Image(.dog)
            .scaledToFit()
            .zoomable()
    }
}

#Preview {
    ContentView()
}
