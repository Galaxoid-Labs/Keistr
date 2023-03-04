//
//  RelayPermission.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import Foundation

struct RelayPermission: Codable {
    let relayId: String
    var write: Bool
    var read: Bool
}

extension RelayPermission: Identifiable, Hashable {
    var id: String { return relayId }
}

extension RelayPermission {
    
    static var preview: RelayPermission {
        return RelayPermission(relayId: "wss://brb.io", write: true, read: true)
    }
    
}
