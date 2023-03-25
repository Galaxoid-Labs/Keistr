//
//  ContentView.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import SwiftUI
import Setting
import SDWebImageSwiftUI

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var webViewPresented = false
    
    var recentInternalSiteSessions: [InternalSiteSession] {
        return appState.internalSiteSessions
            .filter({ $0.bookmarked == false })
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    var bookMarkedInternalSiteSessions: [InternalSiteSession] {
        return appState.internalSiteSessions
            .filter({ $0.bookmarked == true })
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    var body: some View {
        NavigationStack {
            List {

                if self.appState.internalSiteSessions.count > 0 {
                    
                    if self.bookMarkedInternalSiteSessions.count > 0 {
                        Section("Bookmarked") {
                            ForEach(self.bookMarkedInternalSiteSessions) { internalSiteSession in
                                HStack {
                                    WebImage(url: URL(string: internalSiteSession.iconUrl ?? ""))
                                        .placeholder {
                                            RoundedRectangle(cornerRadius: 4)
                                                .foregroundColor(.secondary)
                                                .overlay(
                                                    Image(systemName: "link")
                                                        .foregroundColor(.white)
                                                        .imageScale(.small)
                                                )
                                                .frame(width: 25, height: 25)
                                        }
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .cornerRadius(4)
                                    Text(internalSiteSession.id)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.appState.currentInternalSiteSession = internalSiteSession
                                }
                            }
                        }
                    }
                    
                    if self.recentInternalSiteSessions.count > 0 {
                        Section("Recent") {
                            ForEach(self.recentInternalSiteSessions) { internalSiteSession in
                                HStack {
                                    WebImage(url: URL(string: internalSiteSession.iconUrl ?? ""))
                                        .placeholder {
                                            RoundedRectangle(cornerRadius: 4)
                                                .foregroundColor(.secondary)
                                                .overlay(
                                                    Image(systemName: "link")
                                                        .foregroundColor(.white)
                                                        .imageScale(.small)
                                                )
                                                .frame(width: 25, height: 25)
                                        }
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .cornerRadius(4)
                                    Text(internalSiteSession.id)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.appState.currentInternalSiteSession = internalSiteSession
                                }
                            }
                        }
                    }

                }
                
                Section("Key Management") {
                    NavigationLink {
                        KeysView()
                    } label: {
                        HStack {
                            if appState.ownerKeys.count == 0 {
                                Text("Add or Import Key")
                                Spacer()
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.yellow)
                            } else {
                                Text("Keys")
                            }
                        }
                    }
                    NavigationLink {
                        RelaysView()
                    } label: {
                        HStack {
                            if appState.relays.count == 0 {
                                Text("Add Relay")
                                Spacer()
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.yellow)
                            } else {
                                Text("Relays")
                            }
                        }
                    }
                }

            }
            .navigationTitle("Keistr")
            .searchable(text: .constant("")) {
                
            }
        }
        .fullScreenCover(item: $appState.currentInternalSiteSession, onDismiss: {
            
        }, content: { internalSiteSession in
            NavigationStack {
                NostrWebView(internalSiteSessionViewModel: InternalSiteSessionViewModel(internalSiteSession: internalSiteSession))
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
