//
//  InternalSiteSession.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import Foundation

struct InternalSiteSession: Codable, Identifiable {

    let id: String
    var url: URL
    var updatedAt: Date
    var bookmarked: Bool
    var ownerKeyPublicKey: String?
    var siteManifest: SiteManifest?
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
                  siteManifest: SiteManifest? = nil, iconUrl: String? = nil) {
        self.url = baseUrl
        self.id = id
        self.updatedAt = updatedAt
        self.bookmarked = bookmarked
        self.ownerKeyPublicKey = ownerKeyPublicKey
        self.siteManifest = siteManifest
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
    func fetchManifest() async {
        guard let url = URL(string: internalSiteSession.baseUrl.absoluteString + "/manifest.json") else { return }
        guard let (data, _) = try? await URLSession.shared.data(for: URLRequest(url: url)) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let manifest = try decoder.decode(SiteManifest.self, from: data)
            self.internalSiteSession.siteManifest = manifest
            if let iconPath = self.internalSiteSession.siteManifest?.iconPath {
                self.internalSiteSession.iconUrl = internalSiteSession.baseUrl.absoluteString + "/" + iconPath
            }
        } catch {
            print(error)
        }
    }
    
}
