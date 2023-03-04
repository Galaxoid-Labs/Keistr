//
//  Relay.swift
//  Keistr
//
//  Created by Jacob Davis on 2/26/23.
//

import Foundation

struct Relay: Codable {

    let url: String
    var name: String
    var desc: String
    var contact: String
    var supportedNips: Set<Int>
    var software: String
    var version: String
    var updatedAt: Date
    
    var httpUrl: URL? {
        let httpUrlString = url
            .replacingOccurrences(of: "wss://", with: "https://")
            .replacingOccurrences(of: "ws://", with: "http://")
        return URL(string: httpUrlString)
    }
    
    init?(url: String) {
        if url.validSocketURL() {
            self.init(url: url, name: "", desc: "", contact: "",
                      supportedNips: [], software: "", version: "", updatedAt: .now)
        } else {
            return nil
        }
    }
    
    internal init(url: String, name: String, desc: String, contact: String, supportedNips: Set<Int>, software: String, version: String, updatedAt: Date) {
        self.url = url
        self.name = name
        self.desc = desc
        self.contact = contact
        self.supportedNips = supportedNips
        self.software = software
        self.version = version
        self.updatedAt = updatedAt
    }
    
}

extension Relay: Identifiable, Hashable {
    var id: String { return url }
}

extension Relay {
    
    static var bootStrap: [Relay] {
        return [
            Relay(url: "wss://eden.nostr.land", name: "", desc: "", contact: "", supportedNips: [], software: "", version: "", updatedAt: .now),
            Relay(url: "wss://brb.io", name: "", desc: "", contact: "", supportedNips: [], software: "", version: "", updatedAt: .now)
        ]
    }
    
    static var preview: Relay {
        return Relay(url: "wss://brb.io", name: "", desc: "", contact: "", supportedNips: [], software: "", version: "", updatedAt: .now)
    }
    
}

extension String {
    func validSocketURL() -> Bool {
            let regex = "ws[s]?://(([^/:.[:space:]]+(.[^/:.[:space:]]+)*)|([0-9](.[0-9]{3})))(:[0-9]+)?((/[^?#[:space:]]+)([^#[:space:]]+)?(#.+)?)?"
            let test = NSPredicate(format:"SELF MATCHES %@", regex)
            let result = test.evaluate(with: self)
            return result
     }
    func validURL() -> Bool {
            let regex = "http[s]?://(([^/:.[:space:]]+(.[^/:.[:space:]]+)*)|([0-9](.[0-9]{3})))(:[0-9]+)?((/[^?#[:space:]]+)([^#[:space:]]+)?(#.+)?)?"
            let test = NSPredicate(format:"SELF MATCHES %@", regex)
            let result = test.evaluate(with: self)
            return result
     }
}
