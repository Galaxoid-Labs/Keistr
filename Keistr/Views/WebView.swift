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
    @Published public var webView: WKWebView {
        didSet {
            setupObservers()
        }
    }
    
    @Published public var getPublicKeyPresented = false
    @Published public var signEventPresented = false
    @Published public var unsignedEvent: [String: Any]?
    
    public var nostrjs: String
    
    public init(webView: WKWebView = WKWebView(), nostrjs: String) {
        self.webView = webView
        self.nostrjs = nostrjs
        super.init()
        setupConfiguration()
        setupObservers()
    }
    
    private func setupConfiguration() {
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "getPublicKey")
        contentController.add(self, name: "signEvent")
        
        let script = WKUserScript(source: self.nostrjs, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(script)
        
        let configs = WKWebViewConfiguration()
        configs.userContentController = contentController
        
        self.webView = WKWebView(frame: .zero, configuration: configs)
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

extension WebViewStore: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        switch message.name {
        case "getPublicKey":
            self.getPublicKeyPresented = true
        case "signEvent":
            guard let json = message.body as? String else { return }
            let data = Data(json.utf8)
            do {
                // make sure this JSON is in the format we expect
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self.unsignedEvent = json
                    self.signEventPresented = true
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        default: ()
        }
    }
    public func send(publicKey: String) {
        let script = "window.nostr.handler_getPublicKey('\(publicKey)')"
        webView.evaluateJavaScript(script) { (result, error) in
            if let error {
                print("An error occurred: \(error)")
            }
        }
    }
    public func send(signedEvent event: Event) {
        guard let data = try? JSONEncoder().encode(event) else { return }
        guard let json = String(data: data, encoding: .utf8) else { return }
        let script = "window.nostr.handler_signEvent('\(json)')"
        self.unsignedEvent = nil
        webView.evaluateJavaScript(script) { (result, error) in
            if let error {
                print("An error occurred: \(error)")
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

