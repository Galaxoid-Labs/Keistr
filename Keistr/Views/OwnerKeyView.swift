//
//  OwnerKeyView.swift
//  Keistr
//
//  Created by Jacob Davis on 3/1/23.
//

import SwiftUI
import SDWebImageSwiftUI

struct OwnerKeyView: View {
    
    let publicKey: String
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState

    @State private var nsecRevealed = false
    @State private var hexPublicKey = false
    @State private var metaDataRelayPermissions: [RelayPermission] = []

    var ownerKey: OwnerKey? {
        return appState.ownerKeys.first(where: { $0.publicKey == publicKey })
    }
    
    var body: some View {
        List {
            let keyMetaData = ownerKey?.keyMetaData

            Section {

                ZStack {

                    VStack {
                        if let banner = keyMetaData?.banner, banner.isEmpty == false {
                            WebImage(url: URL(string: banner))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.gray
                        }
                    }
                    .frame(height: 250)
                    
                }
                .overlay(alignment: .bottom) {
                    LazyVStack(alignment: .center) {
                        Spacer(minLength: 25)
                        Text(keyMetaData?.name ?? "")
                            .font(.title)
                            .bold()
                        
                        Text(keyMetaData?.nip05 ?? "")
                            .foregroundColor(.secondary)
                            .bold()
                    }
                    .padding(.vertical)
                    .background(Material.thin)
                    .overlay(alignment: .top) {
                        AvatarView(avatarUrl: keyMetaData?.picture ?? "", size: 85)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(colorScheme == .light ? .white : .gray)
                                    Circle()
                                        .stroke(style: .init(lineWidth: 4))
                                        .fill(colorScheme == .light ? .black : .white)
                                }
                            )
                            .offset(y: -55)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
            }
            
            Section("Public Key") {
                if hexPublicKey {
                    Text(ownerKey?.publicKey ?? "")
                        .textSelection(.enabled)
                        .onTapGesture {
                            self.hexPublicKey.toggle()
                        }
                } else {
                    Text(ownerKey?.bech32PublicKey ?? "")
                        .textSelection(.enabled)
                        .onTapGesture {
                            self.hexPublicKey.toggle()
                        }
                }
            }
            
            Section("Private Key") {
                if nsecRevealed {
                    Text(ownerKey?.getKeyPair()?.bech32PrivateKey ?? "")
                        .textSelection(.enabled)
                        .onTapGesture {
                            self.nsecRevealed.toggle()
                        }
                } else {
                    Text(ownerKey?.publicKey ?? "")
                        .redacted(reason: .placeholder)
                        .onTapGesture {
                            self.nsecRevealed.toggle()
                        }
                }
            }
            
            Section {
                ForEach($metaDataRelayPermissions) { $permission in
                    VStack(alignment: .leading) {
                        Text(permission.relayId)
                        HStack {
                            Text(permission.write ? "Publish" : "Read Only")
                                .foregroundColor(.secondary)
                                .font(Font.callout)
                            Toggle("", isOn: $permission.write)
                                .onChange(of: permission.write) { newValue in
                                    updateRelayPermissions()
                                }
                        }
                    }
                }
            } header: {
                Text("Relays")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            metaDataRelayPermissions = Array(ownerKey?.metaDataRelayPermissions ?? [])
        }
    }
    
    func updateRelayPermissions() {
        if let indexOf = appState.ownerKeys.firstIndex(where: { $0.publicKey == ownerKey?.publicKey }) {
            appState.ownerKeys[indexOf].metaDataRelayPermissions = Set(metaDataRelayPermissions)
        }
    }
    
}

struct OwnerKeyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OwnerKeyView(publicKey: OwnerKey.preview.publicKey)
                .environmentObject(AppState.shared.initPreview())
        }
    }
}
