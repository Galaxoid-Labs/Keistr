//
//  OwnerKey.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import Foundation
import NostrKit
import KeychainAccess

let KeychainService = "keistr"
let KeychainGroup = "MHMRS5FLW6.com.galaxoidlabs.Keistr"

struct OwnerKey: Codable {

    let publicKey: String
    var metaDataRelayPermissions: Set<RelayPermission>
    
    var bech32PublicKey: String? {
        KeyPair.bech32PublicKey(fromHex: publicKey)
    }
    
    var bestPublicName: String {
        if let keyMetaData {
            return keyMetaData.bestPublicName
        } else if let bech32PublicKey {
            return bech32PublicKey
        }
        return publicKey
    }
    
    var bestPublicNameIsPublicKey: Bool {
        return keyMetaData?.bestPublicNameIsPublicKey ?? true
    }
    
    var keyMetaData: KeyMetaData? {
        return AppState.shared.keyMetaData.first(where: { $0.publicKey == publicKey })
    }
    
    init?() {
        guard let keypair = try? KeyPair() else { return nil }
        self.init(privateKey: keypair.privateKey)
    }
    
    init?(privateKey: String) {
        if let keypair = OwnerKey.keyPairFrom(string: privateKey) {
            OwnerKey.saveKeyPairToKeychain(keyPair: keypair)
            self.init(publicKey: keypair.publicKey, metaDataRelayPermissions: [])
        } else {
            return nil
        }
    }
    
    init?(publicKey: String) {
        let keychain = Keychain(service: KeychainService, accessGroup: KeychainGroup)
        guard let _ = try? keychain.getString(publicKey) else {
            return nil
        }
        self.init(publicKey: publicKey, metaDataRelayPermissions: [])
    }
    
    internal init(publicKey: String, metaDataRelayPermissions: Set<RelayPermission>) {
        self.publicKey = publicKey
        self.metaDataRelayPermissions = metaDataRelayPermissions
    }
    
}

extension OwnerKey: Identifiable {
    var id: String { return publicKey }
}

extension OwnerKey {
    
    static func saveKeyPairToKeychain(keyPair: KeyPair) {
        let keychain = Keychain(service: KeychainService, accessGroup: KeychainGroup)
        try? keychain.set(keyPair.privateKey, key: keyPair.publicKey)
    }
    
    static func keyPairFrom(string: String) -> KeyPair? {
        if string.hasPrefix("nsec") {
            return try? KeyPair(bech32PrivateKey: string)
        } else {
            return try? KeyPair(privateKey: string)
        }
    }
    
    func getKeyPair() -> KeyPair? {
        #if targetEnvironment(simulator)
        return nil
        #endif
        let keychain = Keychain(service: KeychainService, accessGroup: KeychainGroup)
        guard let privateKey = try? keychain.getString(publicKey) else {
            return nil
        }
        return try? KeyPair(privateKey: privateKey)
    }
    
    static func getAllValidOwnerKeys() -> [OwnerKey] {
        #if targetEnvironment(simulator)
        return []
        #endif
        let keychain = Keychain(service: KeychainService, accessGroup: KeychainGroup)
        let allKeys = keychain.allKeys()
        return allKeys.compactMap({ OwnerKey(publicKey: $0) })
    }
    
    func deleteKeyPair() {
        let keychain = Keychain(service: KeychainService, accessGroup: KeychainGroup)
        try? keychain.remove(publicKey)
    }
    
    static var preview: OwnerKey {
        return OwnerKey(publicKey: "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778", metaDataRelayPermissions: [
            RelayPermission(relayId: "wss://brb.io", write: true, read: false)
        ])
    }
    
    static var preview2: OwnerKey {
        return OwnerKey(publicKey: "02d2f1ef7604c215a90684c2389435655cd94f63bdf8fbccbd851788470ff345", metaDataRelayPermissions: [])
    }
    
}
