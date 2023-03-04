//
//  ContentView.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import SwiftUI
import Setting

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var webViewPresented = false
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Keys") {
                    KeysView()
                }
                NavigationLink("Relays") {
                    RelaysView()
                }
                Section {
                    Button(action: { self.webViewPresented.toggle() }) {
                        Text("Launch Snort.social")
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .navigationTitle("Keistr")
        }
        .fullScreenCover(isPresented: $webViewPresented, content: {
            NavigationStack {
                NostrWebView()
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState.shared.initPreview())
    }
}
