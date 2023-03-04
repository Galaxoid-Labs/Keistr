//
//  InternalSiteSession.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import Foundation

class InternalSiteSession: ObservableObject {
    
    @Published var siteManifest: SiteManifest?
    @Published var baseUrl: String?
    @Published var iconUrl: String?
    
    func fetchManifest() async {
        guard let baseUrl else { return }
        guard let url = URL(string: baseUrl + "/manifest.json") else { return }
        guard let (data, _) = try? await URLSession.shared.data(for: URLRequest(url: url)) else { return }
        DispatchQueue.main.async {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let manifest = try decoder.decode(SiteManifest.self, from: data)
                self.siteManifest = manifest
                if let iconPath = self.siteManifest?.iconPath {
                    self.iconUrl = baseUrl + "/" + iconPath
                }
            } catch {
                print(error)
            }
        }
    }
    
}
