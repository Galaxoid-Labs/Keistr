//
//  KeistrApp.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import SwiftUI
import SDWebImageSVGCoder

@main
struct KeistrApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { (url) in
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                        if let openUrl = components.queryItems?.first(where: { $0.name == "openUrl" }), var value = openUrl.value {
                            if value.hasSuffix("/") {
                                value.removeLast()
                            }
                            if let internalSiteSession = InternalSiteSession(baseUrlString: value) {
                                if let indexOf = appState.internalSiteSessions.firstIndex(where: { $0.id == internalSiteSession.id }) {
                                    appState.currentInternalSiteSession = appState.internalSiteSessions[indexOf]
                                } else {
                                    appState.currentInternalSiteSession = internalSiteSession
                                }
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $appState.showWelcome) {
                    WelcomeView()
                        .environmentObject(appState)
                }
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                print("🍑 Keistr => Entered Background Phase")
                appState.save()
                appState.disconnectRelays()
            case .active:
                print("🍑 Keistr => Entered Active Phase")
                appState.load()
                appState.connectRelays()
            case .inactive:
                print("🍑 Keistr => Entered Inactive Phase")
                // MACOS - Window in dock
            default:
                print("🍑 Keistr => Entered Unknown Phase")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        return true
    }
}
