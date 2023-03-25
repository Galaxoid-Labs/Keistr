//
//  WebView.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import SwiftUI
import Combine
import WebKit
import NostrKit

@dynamicMemberLookup
public class WebViewStore: NSObject, ObservableObject {
    
    public enum BridgeFunctionNames: String {
        case getPublicKey, signEvent, getRelays, encrypt, decrypt
    }
    
    @Published public var webView: WKWebView {
        didSet {
            setupObservers()
        }
    }
    
    @Published public var getPublicKeyPresented = false
    @Published public var signEventPresented = false
    @Published public var unsignedEvent: [String: Any]?
    @Published public var rawUnsignedEvent: Data?
    
    public var nostrjs: String?
    
    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        if let filepath = Bundle.main.path(forResource: "nostr", ofType: "js") {
            self.nostrjs = try? String(contentsOfFile: filepath)
        }
        super.init()
        setupConfiguration()
        setupObservers()
    }
    
    deinit {
        print("DONE BITCH!")
    }
    
    @objc func reload(sender: UIRefreshControl) {
        DispatchQueue.main.async {
            self.webView.reload()
            sender.endRefreshing()
        }
    }
    
    private func setupConfiguration() {
        
        let contentController = WKUserContentController()
        contentController.add(self, name: BridgeFunctionNames.getPublicKey.rawValue)
        contentController.add(self, name: BridgeFunctionNames.signEvent.rawValue)
        contentController.add(self, name: BridgeFunctionNames.getRelays.rawValue)
        
        if let nostrjs {
            let script = WKUserScript(source: nostrjs, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            contentController.addUserScript(script)
        }

        let configs = WKWebViewConfiguration()
        configs.userContentController = contentController
        
        self.webView = WKWebView(frame: .zero, configuration: configs)
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.allowsLinkPreview = true
        self.webView.uiDelegate = self
        
        // Setup refresh control
        self.webView.scrollView.bounces = true
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.reload), for: UIControl.Event.valueChanged)
        
        self.webView.scrollView.addSubview(refreshControl)
        self.webView.scrollView.refreshControl = refreshControl
    }
    
    private func setupObservers() {
        func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
            return webView.observe(keyPath, options: [.prior]) { _, change in
                if change.isPrior {
                    self.objectWillChange.send()
                }
            }
        }
        // Setup observers for all KVO compliant properties
        observers = [
            subscriber(for: \.title),
            subscriber(for: \.url),
            subscriber(for: \.isLoading),
            subscriber(for: \.estimatedProgress),
            subscriber(for: \.hasOnlySecureContent),
            subscriber(for: \.serverTrust),
            subscriber(for: \.canGoBack),
            subscriber(for: \.canGoForward),
            subscriber(for: \.themeColor),
            subscriber(for: \.underPageBackgroundColor),
            subscriber(for: \.microphoneCaptureState),
            subscriber(for: \.cameraCaptureState),
            subscriber(for: \.fullscreenState)
        ]
    }
    
    private var observers: [NSKeyValueObservation] = []
    
    public subscript<T>(dynamicMember keyPath: KeyPath<WKWebView, T>) -> T {
        webView[keyPath: keyPath]
    }
}

extension WebViewStore: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                        for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

extension WebViewStore: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case BridgeFunctionNames.getPublicKey.rawValue:
            self.getPublicKeyPresented = true
        case BridgeFunctionNames.signEvent.rawValue:
            guard let json = message.body as? String else { return }
            let data = Data(json.utf8)
            do {
                // make sure this JSON is in the format we expect
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    guard let kind = json["kind"] as? Int else { return }
                    self.rawUnsignedEvent = data
                    //self.eventKind = EventKind(id: kind)
                    self.unsignedEvent = json
                    self.signEventPresented = true
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        case BridgeFunctionNames.getRelays.rawValue:
            print(message.name)
        default: ()
        }
    }
    
    public func send(publicKey: String?) {
        if let publicKey {
            let script = "window.nostr.handler_getPublicKey('\(publicKey)')"
            webView.evaluateJavaScript(script) { (result, error) in
                if let error {
                    print("An error occurred: \(error)")
                }
            }
        } else {
            let script = "window.nostr.handler_getPublicKey(undefined)"
            webView.evaluateJavaScript(script) { (result, error) in
                if let error {
                    print("An error occurred: \(error)")
                }
            }
        }
    }
    
    public func send(signedEvent event: Event?) {
        if let event, let data = try? JSONEncoder().encode(event), let json = String(data: data, encoding: .utf8) {
            let script = "window.nostr.handler_signEvent('\(json)')"
            self.unsignedEvent = nil
            webView.evaluateJavaScript(script) { (result, error) in
                if let error {
                    print("An error occurred: \(error)")
                }
            }
        } else {
            let script = "window.nostr.handler_signEvent(undefined)"
            self.unsignedEvent = nil
            webView.evaluateJavaScript(script) { (result, error) in
                if let error {
                    print("An error occurred: \(error)")
                }
            }
        }
    }
    
}

#if os(iOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, UIViewRepresentable {
    /// The WKWebView to display
    public let webView: WKWebView
    
    public init(webView: WKWebView) {
        self.webView = webView
    }
    
    public func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
    }
}
#endif

#if os(macOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, NSViewRepresentable {
    /// The WKWebView to display
    public let webView: WKWebView
    
    public init(webView: WKWebView) {
        self.webView = webView
    }
    
    public func makeNSView(context: NSViewRepresentableContext<WebView>) -> WKWebView {
        webView
    }
    
    public func updateNSView(_ uiView: WKWebView, context: NSViewRepresentableContext<WebView>) {
    }
}
#endif

