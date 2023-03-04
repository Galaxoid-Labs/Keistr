//
//  RelayConnection.swift
//  Keistr
//
//  Created by Jacob Davis on 2/27/23.
//

import Foundation
import NWWebSocket
import Network
import NostrKit

class RelayConnection: NSObject {
    
    let relayUrl: String
    let requiresAuth: Bool
    
    var socket: NWWebSocket?
    var connected = false

    let decoder = JSONDecoder()
    
    var authors: Set<String> = []
    var metaDataSubcription: Subscription?
    var retries: Int = 0
    let retriesMax: Int = 5
    
    init?(relayUrl: String, requiresAuth: Bool = false) {
        
        self.relayUrl = relayUrl
        self.requiresAuth = requiresAuth
        guard let url = URL(string: relayUrl) else { return nil }
        super.init()
        self.socket = NWWebSocket(url: url, connectAutomatically: false, connectionQueue: .global())
        self.socket?.ping(interval: 5)
        self.socket?.delegate = self
    }
    
    func connect() {
        if !connected && retries < retriesMax {
            self.socket?.connect()
        }
    }
    
    func disconnect() {
        if connected {
            self.socket?.disconnect()
        }
    }
    
    func subscribe() {
        if connected {
            
            self.authors = Set(AppState.shared.ownerKeys.compactMap({
                let ownerKey = $0
                if $0.metaDataRelayPermissions.contains(where: { $0.id == self.relayUrl }) {
                    return ownerKey.publicKey
                }
                return nil
            }))
            
            if self.authors.count > 0 {
                if let metaDataSubcription {
                    self.metaDataSubcription = Subscription(filters: [
                        .init(authors: Array(self.authors), eventKinds: [.setMetadata])
                    ], id: metaDataSubcription.id)
                } else {
                    self.metaDataSubcription = Subscription(filters: [
                        .init(authors: Array(self.authors), eventKinds: [.setMetadata])
                    ])
                }
                
                if let metaDataSubcription {
                    if let cm = try? ClientMessage.subscribe(metaDataSubcription).string() {
                        self.socket?.send(string: cm)
                    }
                }
            }
        } else {
            retries += 1
            connect()
        }
    }
    
    func unsubscribe() {
        if let metaDataSubcription, connected {
            if let cm = try? ClientMessage.unsubscribe(metaDataSubcription.id).string() {
                self.socket?.send(string: cm)
            }
            self.metaDataSubcription = nil
        }
    }
    
    private func parse(_ message: RelayMessage) {
        switch message {
        case .event(_, let event): ()
            
            if event.verified() {
                switch event.kind {
                case .setMetadata:
                    
                    let keyMetaData = KeyMetaData(from: event)
                    if let indexOf = AppState.shared.keyMetaData.firstIndex(where: { $0.publicKey == keyMetaData.publicKey }) {
                        if keyMetaData.createdAt > AppState.shared.keyMetaData[indexOf].createdAt {
                            AppState.shared.keyMetaData[indexOf] = keyMetaData
                        }
                    } else {
                        AppState.shared.keyMetaData.append(keyMetaData)
                    }

                case .textNote: ()
                case .recommendServer: ()
                case .encryptedDirectMessage: ()
                case .custom(_): ()
                }
            }
            
        case .notice(let notice):
            print(notice)
        case .other(let others): ()
            if others.count == 2 {
                let op = others[0]
                let subscriptionId = others[1]
                if op == "EOSE" {
                    if subscriptionId == self.metaDataSubcription?.id {
                        AppState.shared.save()
                        print("🍑 Keistr => Metadata EOSE - Sub ID: \(subscriptionId)\n    Relay URL: \(relayUrl)")
                    } else {
                        print("🍑 Keistr => Metadata EOSE \n    Relay URL: \(relayUrl)")
                    }
                }
            }
        }
    }
    
}

extension RelayConnection: WebSocketConnectionDelegate {
    
    func webSocketDidConnect(connection: WebSocketConnection) {
        connected = true
        retries = 0
        print("🍑 Keistr => CONNECTED: \(relayUrl)")
        self.metaDataSubcription = nil
        self.subscribe()
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        connected = false
        print("🍑 Keistr => DISCONNECTED: \(relayUrl)")
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        //print("Connection isViable: \(isViable)")
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        //print("Connection didAttemptBetterPathMigration: \(try? result.get())")
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        print("Connection Error: \(relayUrl) \(error.localizedDescription)")
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        //print("Connection Received Pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        if let relayMessage = try? RelayMessage(text: string) {
            DispatchQueue.main.async {
                self.parse(relayMessage)
            }
        }
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        print("Connection received data: \(String(describing: String(data: data, encoding: .utf8)))")
    }

}
