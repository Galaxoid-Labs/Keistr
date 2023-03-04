//
//  KeyMetaData.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import Foundation
import NostrKit

struct KeyMetaData: Codable {

    let publicKey: String
    var name: String
    var about: String
    var picture: String
    var banner: String
    var nip05: String
    var lud06: String
    var lud16: String
    var createdAt: Date
    var nip05Verified: Bool
    
    var bech32PublicKey: String? {
        KeyPair.bech32PublicKey(fromHex: publicKey)
    }
    
    var bestPublicName: String {
        if !nip05.isEmpty {
            return nip05.replacingOccurrences(of: "_@", with: "")
        } else if !name.isEmpty {
            return name
        } else {
            return bech32PublicKey ?? publicKey
        }
    }
    
    var bestPublicNameIsPublicKey: Bool {
        return nip05.isEmpty && name.isEmpty
    }
    
    init(withPublicKey publicKey: String) {
        self.init(publicKey: publicKey, name: "", about: "", picture: "", banner: "", nip05: "",
                  lud06: "", lud16: "", createdAt: .distantPast, nip05Verified: false)
    }
    
    init(from event: Event) {
        self.init(withPublicKey: event.publicKey)
        self.createdAt = Date(timeIntervalSince1970: Double(event.createdAt.timestamp))
        let decoder = JSONDecoder()
        if let contentData = try? decoder.decode(MetaDataContent.self, from: Data(event.content.utf8)) {
            self.name = contentData.name ?? ""
            self.about = contentData.about ?? ""
            self.picture = contentData.picture ?? ""
            self.banner = contentData.banner ?? ""
            self.lud06 = contentData.lud06 ?? ""
            self.lud16 = contentData.lud16 ?? ""
            self.nip05 = contentData.nip05 ?? ""
        }
    }
    
    internal init(publicKey: String, name: String, about: String, picture: String,
                  banner: String, nip05: String, lud06: String, lud16: String, createdAt: Date, nip05Verified: Bool) {
        self.publicKey = publicKey
        self.name = name
        self.about = about
        self.picture = picture
        self.banner = banner
        self.nip05 = nip05
        self.lud06 = lud06
        self.lud16 = lud16
        self.createdAt = createdAt
        self.nip05Verified = nip05Verified
    }
    
    struct MetaDataContent: Codable {
        var name: String?
        var about: String?
        var picture: String?
        var banner: String?
        var nip05: String?
        var lud06: String?
        var lud16: String?
        var display_name: String?
        var website: String?
    }

}

extension KeyMetaData: Identifiable {
    var id: String { return publicKey }
}

extension KeyMetaData {
    
    static var preview: KeyMetaData {
        return KeyMetaData(publicKey: "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778",
                           name: "Jacob", about: "iOS developer by day, Indie developer by night", picture: "https://void.cat/d/V7hxsMqvLD7bascZMdrwJc.webp", banner: "https://void.cat/d/AniEHLMnJRuk4u1k5iHTUw.webp", nip05: "ismyhc@galaxoidlabs.com",
                           lud06: "", lud16: "", createdAt: .now, nip05Verified: false)
    }
    
}
