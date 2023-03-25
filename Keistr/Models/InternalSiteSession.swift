//
//  InternalSiteSession.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import Foundation
import FaviconFinder

struct InternalSiteSession: Codable, Identifiable {

    let id: String
    var url: URL
    var updatedAt: Date
    var bookmarked: Bool
    var ownerKeyPublicKey: String?
    var iconUrl: String?
    
    var baseUrl: URL {
        return url.deletingLastPathComponent()
    }
    
    init?(baseUrlString: String) {
        guard let url = URL(string: baseUrlString) else { return nil }
        guard let host = url.host() else { return nil }
        self.init(id: host, baseUrl: url, updatedAt: .now, bookmarked: false)
    }

    internal init(id: String, baseUrl: URL, updatedAt: Date, bookmarked: Bool, ownerKeyPublicKey: String? = nil,
                  iconUrl: String? = nil) {
        self.url = baseUrl
        self.id = id
        self.updatedAt = updatedAt
        self.bookmarked = bookmarked
        self.ownerKeyPublicKey = ownerKeyPublicKey
        self.iconUrl = iconUrl
    }
    
}

extension InternalSiteSession {
    static var preview: InternalSiteSession {
        return InternalSiteSession(id: "snort.social", baseUrl: URL(string: "https://snort.social")!, updatedAt: .now, bookmarked: true, iconUrl: "https://snort.social/nostrich_256.png")
    }
}

class InternalSiteSessionViewModel: ObservableObject {
    
    @Published var internalSiteSession: InternalSiteSession
    
    init(internalSiteSession: InternalSiteSession) {
        self.internalSiteSession = internalSiteSession
    }
    
    @MainActor
    func fetchIcon() async {
        
        do {
            let favicon = try await FaviconFinder(
                url: internalSiteSession.url,
                preferredType: .html,
                preferences: [
                    .html: FaviconType.appleTouchIcon.rawValue,
                    .ico: "favicon.ico",
                    .webApplicationManifestFile: FaviconType.launcherIcon4x.rawValue
                ],
                downloadImage: false
            )
            .downloadFavicon()

            internalSiteSession.iconUrl = favicon.url.absoluteString

            if let indexOf = AppState.shared.internalSiteSessions.firstIndex(where: { $0.id == internalSiteSession.id }) {
                AppState.shared.internalSiteSessions[indexOf].iconUrl = internalSiteSession.iconUrl
            }

        } catch let error {
            print("Error fetching favicon: \(error)")
        }
        
    }
    
}
