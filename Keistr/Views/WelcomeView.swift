//
//  WelcomeView.swift
//  Keistr
//
//  Created by Jacob Davis on 3/4/23.
//

import SwiftUI

struct WelcomeView: View {
    
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            
            VStack {
                
                Image("keistr_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 1) // ?
                
                Text("Keistr")
                    .font(.system(size: 46, weight: .black, design: .default))
                    .italic()
                Text("A secure key store and event Signer for Nostr")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .edgesIgnoringSafeArea(.top)

            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    self.dismiss()
                }) {
                    Text("Get Started")
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppState.shared)
    }
}
