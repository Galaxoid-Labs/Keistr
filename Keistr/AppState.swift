//
//  AppState.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import Foundation
import KeychainAccess

class AppState: ObservableObject {
    
    @Published var ownerKeys: [OwnerKey] = []
    @Published var keyMetaData: [KeyMetaData] = []
    @Published var relays: [Relay] = []
    
    var relayConnections: [RelayConnection] = []
    
    private let defaults = UserDefaults(suiteName: "MHMRS5FLW6.group.com.galaxoidlabs.Keistr")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    static let shared = AppState()
    
    var nostrjs: String = ""
    
    private init() {
        if let filepath = Bundle.main.path(forResource: "nostr", ofType: "js") {
            do {
                let contents = try String(contentsOfFile: filepath)
                print(contents)
                nostrjs = contents
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func initPreview() -> AppState {
        ownerKeys.removeAll()
        keyMetaData.removeAll()
        relays.removeAll()
        ownerKeys.append(contentsOf: [OwnerKey.preview, OwnerKey.preview2])
        keyMetaData.append(KeyMetaData.preview)
        relays.append(contentsOf: Relay.bootStrap)
        return .shared
    }
    
    func load() {
        if let ownerKeysData = defaults?.object(forKey: "ownerKeys") as? Data {
            if let ownerKeys = try? decoder.decode([OwnerKey].self, from: ownerKeysData) {
                self.ownerKeys = ownerKeys
            }
        }
        if let keyMetaDataData = defaults?.object(forKey: "keyMetaData") as? Data {
            if let keyMetaData = try? decoder.decode([KeyMetaData].self, from: keyMetaDataData) {
                self.keyMetaData = keyMetaData
            }
        }
        if let relaysData = defaults?.object(forKey: "relays") as? Data {
            if let relays = try? decoder.decode([Relay].self, from: relaysData) {
                self.relays = relays
            }
        }
    }
    
    func connectRelays() {
        let relays = self.relays.map({ $0.url })
        self.relayConnections.forEach({ $0.disconnect() })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.relayConnections = relays.compactMap({ RelayConnection(relayUrl: $0) })
            if self.ownerKeys.count > 0 {
                for connection in self.relayConnections {
                    connection.connect()
                }
            }
        }
    }
    
    func disconnectRelays() {
        self.relayConnections.forEach({ $0.disconnect() })
    }
    
    func save() {
        if let encodedOwnerKeys = try? encoder.encode(ownerKeys) {
            defaults?.set(encodedOwnerKeys, forKey: "ownerKeys")
        }
        if let encodedKeyMetaData = try? encoder.encode(keyMetaData) {
            defaults?.set(encodedKeyMetaData, forKey: "keyMetaData")
        }
        if let encodedRelays = try? encoder.encode(relays) {
            defaults?.set(encodedRelays, forKey: "relays")
        }
    }
    
    func importNewKey(withPrivateKey privateKey: String) -> Bool {
        if var ownerKey = OwnerKey(privateKey: privateKey) {
            if ownerKeys.first(where: { $0.publicKey == ownerKey.publicKey }) == nil {
                if self.ownerKeys.count == 0 {
                    ownerKey.defaultKey = true
                }
                ownerKey.metaDataRelayPermissions = Set(self.relays.map({ RelayPermission(relayId: $0.id, write: false, read: true) }))
                ownerKeys.append(ownerKey)
                if keyMetaData.first(where: { $0.publicKey == ownerKey.publicKey }) == nil {
                    keyMetaData.append(KeyMetaData(withPublicKey: ownerKey.publicKey))
                }
                connectRelays()
                save()
                return true
            }
        }
        return false
    }
    
    func addNewKey() -> Bool {
        guard var ownerKey = OwnerKey() else { return false }
        let keyMetaData = KeyMetaData(withPublicKey: ownerKey.publicKey)
        if self.ownerKeys.count == 0 {
            ownerKey.defaultKey = true
        }
        ownerKey.metaDataRelayPermissions = Set(self.relays.map({ RelayPermission(relayId: $0.id, write: false, read: true) }))
        self.ownerKeys.insert(ownerKey, at: 0)
        self.keyMetaData.insert(keyMetaData, at: 0)
        connectRelays()
        save()
        return true
    }
    
    func remove(ownerKeyAt offsets: IndexSet) {
        
        // Delete keys from keychain
        let ownerKeys = offsets.map({ self.ownerKeys[$0] })
        ownerKeys.forEach({ $0.deleteKeyPair() })
        
        // Remove ownerkeys
        self.ownerKeys.remove(atOffsets: offsets)
        
        // Remove keymetadata
        let publicKeys = ownerKeys.map({ $0.publicKey })
        publicKeys.forEach { publicKey in
            self.keyMetaData.removeAll(where: { $0.publicKey == publicKey })
        }

        if self.ownerKeys.contains(where: { $0.defaultKey == true }) == false {
            if self.ownerKeys.count > 0 {
                self.ownerKeys[0].defaultKey = true
            }
        }
        connectRelays()
        save()
    }
    
    func add(relay: Relay) {
        if !self.relays.contains(where: { $0.id == relay.id }) {
            self.relays.insert(relay, at: 0)
            for (idx, ownerKey) in self.ownerKeys.enumerated() {
                if !ownerKey.metaDataRelayPermissions.contains(where: { $0.id == relay.id }) {
                    self.ownerKeys[idx].metaDataRelayPermissions.insert(RelayPermission(relayId: relay.id, write: false, read: true))
                }
            }
        }
        connectRelays()
        save()
    }
    
    func remove(relayAt offsets: IndexSet) {
        
        let relays = offsets.map({ self.relays[$0] })
        self.relays.remove(atOffsets: offsets)
        
        relays.forEach({
            
            let relay = $0
            
            // Remove from OwnerKeys
            for (idx, ownerKey) in self.ownerKeys.enumerated() {
                if ownerKey.metaDataRelayPermissions.contains(where: { $0.id == relay.id }) {
                    if let indexOf = self.ownerKeys[idx].metaDataRelayPermissions.firstIndex(where: { $0.id == relay.id }) {
                        self.ownerKeys[idx].metaDataRelayPermissions.remove(at: indexOf)
                    }
                }
            }
            
            // Disconnect and remove RelayConnection
            if let indexOf = self.relayConnections.firstIndex(where: { $0.relayUrl == relay.id }) {
                self.relayConnections[indexOf].disconnect()
                self.relayConnections.remove(at: indexOf)
            }
            
        })
        connectRelays()
        save()
        
    }
    
}
