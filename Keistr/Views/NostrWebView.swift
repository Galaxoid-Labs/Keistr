//
//  NostrWebView.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import SwiftUI
import NostrKit
import SDWebImageSwiftUI
import Haptica

struct NostrWebView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @StateObject var webViewStore = WebViewStore()
    @StateObject var internalSiteSessionViewModel: InternalSiteSessionViewModel
    
    var ownerKeys: [OwnerKey] {
        return appState.ownerKeys
    }
    
    var title: String {
        return webViewStore.webView.url?.host() ?? ""
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
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        self.bookmark()
                    }) {
                        Image(systemName: isBookmarked() ? "bookmark.fill" : "bookmark")
                    }
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .frame(width: 25)
                    }
                    .disabled(!webViewStore.canGoBack)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)

                    Button(action: goForward) {
                        Image(systemName: "chevron.right")
                            .frame(width: 25)
                    }
                    .disabled(!webViewStore.canGoForward)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)

                    Text(self.webViewStore.webView.url?.absoluteString ?? "")
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(height: 100)
                        .font(.caption)
                        .padding(.leading, 12)
                        .padding(.trailing, 24)
                    
                    Spacer()

                }
            }
            .onAppear {
                self.webViewStore.webView.load(URLRequest(url: self.internalSiteSessionViewModel.internalSiteSession.url))
                Task {
                    await self.internalSiteSessionViewModel.fetchManifest()
                }
            }
            .sheet(isPresented: $webViewStore.getPublicKeyPresented) {
                NavigationStack {
                    List {
                        ForEach(ownerKeys) { ownerKey in
                            SelectKeyListView(ownerKey: ownerKey)
                                .onTapGesture {
                                    self.internalSiteSessionViewModel.internalSiteSession.ownerKeyPublicKey = ownerKey.publicKey
                                    self.internalSiteSessionViewModel.internalSiteSession.updatedAt = .now
                                    self.webViewStore.send(publicKey: ownerKey.publicKey)
                                    self.webViewStore.getPublicKeyPresented = false
                                    self.appState.update(internalSiteSession: self.internalSiteSessionViewModel.internalSiteSession)
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
                        WebImage(url: URL(string: self.internalSiteSessionViewModel.internalSiteSession.iconUrl ?? ""))
                            .placeholder {
                                Image(systemName: "network")
                                    .resizable()
                                    .imageScale(.medium)
                                    .frame(width: 65, height: 65)
                                    .background(
                                        Color.gray
                                    )
                                    .cornerRadius(12)
                            }
                            .resizable()
                            .frame(width: 65, height: 65)
                            .cornerRadius(12)
                    }
                    .navigationTitle("Sign Event")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .fraction(0.5)])
                .presentationDragIndicator(.hidden)
                .safeAreaInset(edge: .bottom) {
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
            }
    }
    
    func bookmark() {
        if let current = self.webViewStore.webView.url {
            let base = current.deletingLastPathComponent()
            if let host = base.host() {
                if host == self.internalSiteSessionViewModel.internalSiteSession.id {
                    self.internalSiteSessionViewModel.internalSiteSession.bookmarked = !self.internalSiteSessionViewModel.internalSiteSession.bookmarked
                    self.internalSiteSessionViewModel.internalSiteSession.url = current
                    self.appState.update(internalSiteSession: self.internalSiteSessionViewModel.internalSiteSession)
                } else {
                    if var internalSiteSession = self.appState.internalSiteSessions.first(where: { $0.id == host }) {
                        internalSiteSession.url = current
                        internalSiteSession.bookmarked = !internalSiteSession.bookmarked
                        internalSiteSession.updatedAt = .now
                        self.appState.update(internalSiteSession: internalSiteSession)
                        self.appState.currentInternalSiteSession = internalSiteSession
                        self.internalSiteSessionViewModel.internalSiteSession = internalSiteSession
                    } else if var internalSiteSession = InternalSiteSession(baseUrlString: current.absoluteString) {
                        internalSiteSession.bookmarked = !internalSiteSession.bookmarked
                        internalSiteSession.updatedAt = .now
                        self.appState.add(internalSiteSession: internalSiteSession)
                        self.internalSiteSessionViewModel.internalSiteSession = internalSiteSession
                    }
                    Task {
                        await self.internalSiteSessionViewModel.fetchManifest()
                    }
                }
            }
            Haptic.notification(.success).generate()
        }
    }
    
    func isBookmarked() -> Bool {
        if let host = self.webViewStore.webView.url?.host() {
            if host == self.internalSiteSessionViewModel.internalSiteSession.id {
                return self.internalSiteSessionViewModel.internalSiteSession.bookmarked
            } else if let _ = self.appState.internalSiteSessions.first(where: { $0.id == host && $0.bookmarked }) {
                return true
            }
        }
        return false
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
        
        guard let ownerKey = self.appState.ownerKeys.first(where: { $0.publicKey == self.internalSiteSessionViewModel.internalSiteSession.ownerKeyPublicKey }) else { return }
        guard let keypair = ownerKey.getKeyPair() else { return }
        
        do {
            let event = try Event(keyPair: keypair, id: id, publicKey: publicKey,
                                  createdAt: createdAt, kind: eventKind, tags: eventTags, content: content)
            self.webViewStore.send(signedEvent: event)
            self.internalSiteSessionViewModel.internalSiteSession.updatedAt = .now
            self.appState.update(internalSiteSession: self.internalSiteSessionViewModel.internalSiteSession)
        } catch {
            print(error.localizedDescription)
        }

    }
}

struct NostrWebView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NostrWebView(internalSiteSessionViewModel: InternalSiteSessionViewModel(internalSiteSession: InternalSiteSession.preview))
                .environmentObject(AppState.shared.initPreview())
        }
    }
}

