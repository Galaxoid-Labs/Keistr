//
//  NostrWebView.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import SwiftUI
import NostrKit

struct NostrWebView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject var webViewStore = WebViewStore(nostrjs: AppState.shared.nostrjs)
    
    @EnvironmentObject var appState: AppState
    
    var ownerKeys: [OwnerKey] {
        return appState.ownerKeys
    }
    
    var title: String {
        return webViewStore.url?.host ?? ""
    }
    
    var body: some View {
        WebView(webView: webViewStore.webView)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!webViewStore.canGoBack)
                    .buttonStyle(.bordered)
                    Button(action: goForward) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!webViewStore.canGoForward)
                    .buttonStyle(.bordered)
                }
            }
            .edgesIgnoringSafeArea(.vertical)
            .toolbar(.hidden, for: .bottomBar)
            .onAppear {
                self.webViewStore.webView.load(URLRequest(url: URL(string: "https://snort.social")!))
            }
            .sheet(isPresented: $webViewStore.getPublicKeyPresented) {
                NavigationStack {
                    List {
                        ForEach(ownerKeys) { ownerKey in
                            SelectKeyListView(ownerKey: ownerKey)
                                .onTapGesture {
                                    self.webViewStore.send(publicKey: ownerKey.publicKey)
                                    self.webViewStore.getPublicKeyPresented = false
                                }
                                .contentShape(Rectangle())

                        }
                    }
                    .navigationTitle("Select Key")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .fraction(0.3)])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $webViewStore.signEventPresented) {
                NavigationStack {
                    VStack {
                        Button(action: {
                            self.signEvent()
                            self.webViewStore.signEventPresented = false
                        }) {
                            Text("Confirm")
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .navigationTitle("Sign Event")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .fraction(0.2)])
                .presentationDragIndicator(.hidden)
            }
    }
    
    func goBack() {
      webViewStore.webView.goBack()
    }
    
    func goForward() {
      webViewStore.webView.goForward()
    }
    
    func signEvent() {
        guard let unsignedEvent = self.webViewStore.unsignedEvent else { return }
        guard let id = unsignedEvent["id"] as? String else { return }
        guard let publicKey = unsignedEvent["pubkey"] as? String else { return }
        guard let created_at = unsignedEvent["created_at"] as? Int else { return }
        let createdAt = Timestamp(timestamp: created_at)
        guard let kind = unsignedEvent["kind"] as? Int else { return }
        let eventKind = EventKind(id: kind)
        guard let tags = unsignedEvent["tags"] as? [[String]] else { return }
        let eventTags = tags.map({ EventTag(underlyingData: $0) })
        guard let content = unsignedEvent["content"] as? String else { return }
        
        guard let ownerKey = self.appState.ownerKeys.first(where: { $0.publicKey == publicKey }) else { return }
        guard let keypair = ownerKey.getKeyPair() else { return }
        
        do {
            let event = try Event(keyPair: keypair, id: id, publicKey: publicKey,
                                  createdAt: createdAt, kind: eventKind, tags: eventTags, content: content)
            self.webViewStore.send(signedEvent: event)
        } catch {
            print(error.localizedDescription)
        }

    }
}

struct NostrWebView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NostrWebView()
                .environmentObject(AppState.shared.initPreview())
        }
    }
}

