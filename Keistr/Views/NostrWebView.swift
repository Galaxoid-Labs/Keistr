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
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var webViewStore = WebViewStore()
    @StateObject var internalSiteSessionViewModel: InternalSiteSessionViewModel
    
    @State private var signExpanded = false
    @State private var signSheetFraction = 0.35
    
    var ownerKeys: [OwnerKey] {
        return appState.ownerKeys
    }
    
    var title: String {
        return webViewStore.webView.url?.host() ?? ""
    }
    
    var body: some View {
        WebView(webView: webViewStore.webView)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("background"))) { _ in
                self.webViewStore.webView.setAllMediaPlaybackSuspended(true)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("active"))) { _ in
                self.webViewStore.webView.setAllMediaPlaybackSuspended(false)
            }
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
                    await self.internalSiteSessionViewModel.fetchIcon()
                }
            }
            .onDisappear {
                self.webViewStore.webView.setAllMediaPlaybackSuspended(true)
            }
            .sheet(isPresented: $webViewStore.getPublicKeyPresented) {
                VStack(spacing: 0) {
                    
                    HStack {
                        
                        VStack(alignment: .leading) {
                            Text("Login Request")
                                .font(.title)
                                .bold()
                            Text(self.title)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        WebImage(url: URL(string: self.internalSiteSessionViewModel.internalSiteSession.iconUrl ?? ""))
                            .placeholder {
                                Image(systemName: "network")
                                    .resizable()
                                    .imageScale(.medium)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Color.gray
                                    )
                                    .cornerRadius(12)
                            }
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(12)
                        
                        

                    }
                    .padding()
                    
                    Divider()

                    List {
                        ForEach(ownerKeys) { ownerKey in
                            SelectKeyListView(ownerKey: ownerKey)
                                .onTapGesture {
                                    self.sendPublicKey(ownerKey: ownerKey)
                                }
                                .contentShape(Rectangle())
                        }
                    }
                    .scrollContentBackground(.visible)
                    .edgesIgnoringSafeArea(.bottom)

                }
                .presentationDetents([.medium, .large]) // TODO: Make this height based on number of accounts..
                .presentationDragIndicator(.hidden)
                .edgesIgnoringSafeArea(.bottom)
            }
            .sheet(isPresented: $webViewStore.signEventPresented) {
                
                VStack(spacing: 0) {
                    
                    HStack {
                        
                        VStack(alignment: .leading) {
                            Text("Signature Request")
                                .font(.title)
                                .bold()
                            Text(self.title)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        WebImage(url: URL(string: self.internalSiteSessionViewModel.internalSiteSession.iconUrl ?? ""))
                            .placeholder {
                                Image(systemName: "network")
                                    .resizable()
                                    .imageScale(.medium)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Color.gray
                                    )
                                    .cornerRadius(12)
                            }
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(12)

                    }
                    .padding()
                    
                    Divider()

                    List {

                        DisclosureGroup(isExpanded: $signExpanded) {
                            Text(self.webViewStore.rawUnsignedEvent?.prettyJson ?? "")
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundColor(.secondary)
                        } label: {
                            Text("View Raw Event")
                                .foregroundColor(.accentColor)
                        }
                        .onChange(of: signExpanded) { newValue in
                            withAnimation {
                                if newValue {
                                    self.signSheetFraction = 1.0
                                } else {
                                    self.signSheetFraction = 0.35
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.visible)
                    .edgesIgnoringSafeArea(.bottom)
                    
                }
                .presentationDetents([.fraction(signSheetFraction), .large])
                .presentationDragIndicator(.hidden)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Button(action: {
                            self.webViewStore.send(signedEvent: nil)
                            self.webViewStore.signEventPresented = false
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            self.signEvent()
                            self.webViewStore.signEventPresented = false
                        }) {
                            Text("Confirm")
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .buttonStyle(.borderedProminent)
                        
                    }
                    .padding()
                    .background(Color.clear)
                    .edgesIgnoringSafeArea(.bottom)
                }
                .interactiveDismissDisabled()
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
                        self.appState.currentInternalSiteSession = internalSiteSession
                        self.internalSiteSessionViewModel.internalSiteSession = internalSiteSession
                    }
                    Task {
                        await self.internalSiteSessionViewModel.fetchIcon()
                    }
                }
            }
            Haptic.notification(.success).generate()
        }
    }
    
    func sendPublicKey(ownerKey: OwnerKey) {
        if let current = self.webViewStore.webView.url {
            let base = current.deletingLastPathComponent()
            if let host = base.host() {
                if host == self.internalSiteSessionViewModel.internalSiteSession.id {
                    self.internalSiteSessionViewModel.internalSiteSession.ownerKeyPublicKey = ownerKey.publicKey
                    self.internalSiteSessionViewModel.internalSiteSession.updatedAt = .now
                    self.webViewStore.send(publicKey: ownerKey.publicKey)
                    self.appState.update(internalSiteSession: self.internalSiteSessionViewModel.internalSiteSession)
                    
                    self.webViewStore.getPublicKeyPresented = false
                    
                } else {
                    if var internalSiteSession = self.appState.internalSiteSessions.first(where: { $0.id == host }) {
                        internalSiteSession.url = current
                        internalSiteSession.ownerKeyPublicKey = ownerKey.publicKey
                        internalSiteSession.updatedAt = .now
                        self.appState.update(internalSiteSession: internalSiteSession)
                        self.appState.currentInternalSiteSession = internalSiteSession
                        self.internalSiteSessionViewModel.internalSiteSession = internalSiteSession
                        
                        self.webViewStore.getPublicKeyPresented = false

                    } else if var internalSiteSession = InternalSiteSession(baseUrlString: current.absoluteString) {
                        internalSiteSession.url = current
                        internalSiteSession.ownerKeyPublicKey = ownerKey.publicKey
                        internalSiteSession.updatedAt = .now
                        
                        self.appState.add(internalSiteSession: internalSiteSession)
                        self.appState.currentInternalSiteSession = internalSiteSession
                        self.internalSiteSessionViewModel.internalSiteSession = internalSiteSession
                        
                        self.webViewStore.getPublicKeyPresented = false
                    }
                    Task {
                        await self.internalSiteSessionViewModel.fetchIcon()
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

        guard let unsignedEvent = self.webViewStore.unsignedEvent else { self.webViewStore.send(signedEvent: nil); return }
        guard let kind = unsignedEvent["kind"] as? Int else { self.webViewStore.send(signedEvent: nil); return }
        let eventKind = EventKind(id: kind)
        guard let tags = unsignedEvent["tags"] as? [[String]] else { self.webViewStore.send(signedEvent: nil); return }
        let eventTags = tags.map({ EventTag(underlyingData: $0) })
        guard let content = unsignedEvent["content"] as? String else { self.webViewStore.send(signedEvent: nil); return }
        
        guard let ownerKey = self.appState.ownerKeys.first(where: { $0.publicKey == self.internalSiteSessionViewModel.internalSiteSession.ownerKeyPublicKey }) else { return }
        guard let keypair = ownerKey.getKeyPair() else { self.webViewStore.send(signedEvent: nil); return }
        
        let id = unsignedEvent["id"] as? String
        let publicKey = unsignedEvent["pubkey"] as? String
        let created_at = unsignedEvent["created_at"] as? Int
        
        var event: Event?
        
        if let id, let publicKey, let created_at {
            let createdAt = Timestamp(timestamp: created_at)
            event = try? Event(keyPair: keypair, id: id, publicKey: publicKey,
                               createdAt: createdAt, kind: eventKind, tags: eventTags, content: content)
        } else {
            event = try? Event(keyPair: keypair, kind: eventKind, tags: eventTags, content: content)
        }
        
        if let event {
            self.webViewStore.send(signedEvent: event)
            self.internalSiteSessionViewModel.internalSiteSession.updatedAt = .now
            self.appState.update(internalSiteSession: self.internalSiteSessionViewModel.internalSiteSession)
            Haptic.notification(.success).generate()
        } else {
            self.webViewStore.send(signedEvent: nil); return
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

extension Data {
    var prettyJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding:.utf8) else { return nil }

        return prettyPrintedString
    }
}
