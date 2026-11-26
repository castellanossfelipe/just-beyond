//
//  ContentView.swift
//  JustBeyond
//
//  Created by Felipe on 11/25/26.
//

import SwiftUI
import JBSim

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text(JBSim.moduleName)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
