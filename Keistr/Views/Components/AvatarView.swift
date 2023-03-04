//
//  AvatarView.swift
//  Keistr
//
//  Created by Jacob Davis on 2/28/23.
//

import SwiftUI
import SDWebImageSwiftUI

struct AvatarView: View {
    
    let avatarUrl: String
    let size: CGFloat
    
    var body: some View {
        if avatarUrl.isEmpty {
            Image(systemName: "person.crop.circle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: size))
                .frame(width: size, height: size)
                .aspectRatio(contentMode: .fill)
                .cornerRadius(size/2)
        } else {
            AnimatedImage(url: URL(string: avatarUrl))
                .placeholder(content: {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.secondary).font(.system(size: size))
                })
                .resizable()
                .frame(width: size, height: size)
                .aspectRatio(contentMode: .fill)
                .cornerRadius(size/2)
        }
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarView(avatarUrl: "", size: 40)
    }
}
