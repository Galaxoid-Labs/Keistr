//
//  AppState.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import Foundation
import KeychainAccess

struct InternalSiteUrl: Identifiable {
    var url: URL
    var id: String {
        return url.host() ?? url.absoluteString
    }
}

class AppState: ObservableObject {
    
    @Published var ownerKeys: [OwnerKey] = []
    @Published var keyMetaData: [KeyMetaData] = []
    @Published var relays: [Relay] = []
    @Published var internalSiteSessions: [InternalSiteSession] = []
    @Published var currentInternalSiteSession: InternalSiteSession?
    
    @Published var showWelcome: Bool = false

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
        internalSiteSessions.removeAll()
        ownerKeys.append(contentsOf: [OwnerKey.preview, OwnerKey.preview2])
        keyMetaData.append(KeyMetaData.preview)
        relays.append(contentsOf: Relay.bootStrap)
        internalSiteSessions.append(InternalSiteSession.preview)
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
        if let internalSiteSessionsData = defaults?.object(forKey: "internalSiteSessions") as? Data {
            if let internalSiteSessions = try? decoder.decode([InternalSiteSession].self, from: internalSiteSessionsData) {
                self.internalSiteSessions = internalSiteSessions
            }
        }
        self.showWelcome = (self.ownerKeys.count == 0)
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
        if let encodedInternalSiteSessions = try? encoder.encode(internalSiteSessions) {
            defaults?.set(encodedInternalSiteSessions, forKey: "internalSiteSessions")
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
    
    func importNewKey(withPrivateKey privateKey: String) -> Bool {
        if var ownerKey = OwnerKey(privateKey: privateKey) {
            if ownerKeys.first(where: { $0.publicKey == ownerKey.publicKey }) == nil {
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
    
    func searchAndImportFromKeychain() -> Bool {
        let ownerKeys = OwnerKey.getAllValidOwnerKeys()
        var newKeysFound = 0
        for var ownerKey in ownerKeys {
            if self.ownerKeys.contains(where: { $0.publicKey == ownerKey.publicKey }) {
                continue
            } else {
                ownerKey.metaDataRelayPermissions = Set(self.relays.map({ RelayPermission(relayId: $0.id, write: false, read: true) }))
                self.ownerKeys.append(ownerKey)
                if keyMetaData.first(where: { $0.publicKey == ownerKey.publicKey }) == nil {
                    keyMetaData.append(KeyMetaData(withPublicKey: ownerKey.publicKey))
                }
                newKeysFound += 1
            }
        }
        if newKeysFound > 0 {
            connectRelays()
            save()
            return true
        }
        return false
    }
    
    func addNewKey() -> Bool {
        guard var ownerKey = OwnerKey() else { return false }
        let keyMetaData = KeyMetaData(withPublicKey: ownerKey.publicKey)
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
    
    func add(internalSiteSession: InternalSiteSession) {
        if !self.internalSiteSessions.contains(where: { $0.id == internalSiteSession.id }) {
            self.internalSiteSessions.insert(internalSiteSession, at: 0)
        }
        save()
    }
    
    func update(internalSiteSession: InternalSiteSession) {
        if let indexOf = self.internalSiteSessions.firstIndex(where: { $0.id == internalSiteSession.id }) {
            self.internalSiteSessions[indexOf] = internalSiteSession
        } else {
            self.internalSiteSessions.insert(internalSiteSession, at: 0)
        }
        save()
    }
    
}
