//
//  SiteManifest.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import Foundation

struct SiteManifest: Codable {
    
    struct Icon: Codable {
        let src: String
        let type: String
        let sizes: String
    }
    
    let shortName: String
    let name: String
    let description: String
    let icons: [SiteManifest.Icon]
    
    var iconPath: String? {
        self.icons.first.map({ $0.src })
    }
    
}
