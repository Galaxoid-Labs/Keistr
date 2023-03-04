//
//  SelectKeyListView.swift
//  Keistr
//
//  Created by Jacob Davis on 3/3/23.
//

import SwiftUI

struct SelectKeyListView: View {
    
    let ownerKey: OwnerKey
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                let keyMetaData = ownerKey.keyMetaData
                AvatarView(avatarUrl: keyMetaData?.picture ?? "", size: 50)
                VStack(alignment: .leading) {
                    if ownerKey.bestPublicNameIsPublicKey == false {
                        Text(ownerKey.bestPublicName)
                            .bold()
                        Text(ownerKey.bech32PublicKey ?? "")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    } else {
                        Text(ownerKey.bech32PublicKey ?? "")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12))
        .overlay(alignment: .leading) {
            if ownerKey.defaultKey {
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: 4)
            }
        }
    }
}

struct SelectKeyListView_Previews: PreviewProvider {
    static var previews: some View {
        SelectKeyListView(ownerKey: OwnerKey.preview)
    }
}
