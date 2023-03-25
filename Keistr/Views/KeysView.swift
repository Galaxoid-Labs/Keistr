//
//  KeysView.swift
//  Keistr
//
//  Created by Jacob Davis on 2/28/23.
//

import SwiftUI
import AlertToast

struct KeysView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var inputFieldText = ""
    @State private var adding = false
    @State private var addConfirmationPresented = false
    @State private var noKeysFoundFromSearchToast = false
    @FocusState private var focus: Bool
    
    var keys: [OwnerKey] {
        return appState.ownerKeys
    }
    
    var body: some View {
        List {
            
            if adding {
                Section {
                    TextField("nsec1...", text: $inputFieldText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focus)
                        .submitLabel(.done)
                        .onSubmit({
                            self.add()
                        })
                }
            }
            
            if keys.count == 0 && self.adding == false {
                
                LazyVStack {
                    
                    Button(action: {
                        withAnimation {
                            self.adding.toggle()
                            self.focus.toggle()
                        }
                    }) {
                        Text("Import")
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        withAnimation {
                            self.new()
                        }
                    }) {
                        Text("Create New Key")
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        withAnimation {
                            if self.appState.searchAndImportFromKeychain() == false {
                                noKeysFoundFromSearchToast = true
                            }
                        }
                    }) {
                        Text("Check for keys in keychain?")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)

                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
            } else {
                
                Section {
                    ForEach(keys) { ownerKey in
                        
                        NavigationLink(destination: OwnerKeyView(publicKey: ownerKey.publicKey).environmentObject(appState)) {
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
//                            .overlay(alignment: .leading) {
//                                if ownerKey.defaultKey {
//                                    Rectangle()
//                                        .foregroundColor(.accentColor)
//                                        .frame(width: 4)
//                                }
//                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12))
                    }
                    .onDelete(perform: delete)
                }
                
            }

        }
        .toolbar {
            
            if adding {

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        withAnimation {
                            self.inputFieldText = ""
                            self.adding.toggle()
                            self.focus.toggle()
                        }
                    }) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                }
                
                if adding && validKey() {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            withAnimation {
                                self.add()
                            }
                        }) {
                           Image(systemName: "checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!validKey())
                    }
                }

            } else if keys.count > 0 {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        withAnimation {
                            self.addConfirmationPresented = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }

        }
        .navigationTitle("Keys")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Select a color", isPresented: $addConfirmationPresented, titleVisibility: .hidden) {
            Button("New Key") {
                withAnimation {
                    self.new()
                }
            }
            Button("Import") {
                withAnimation {
                    self.adding.toggle()
                    self.focus.toggle()
                }
            }
            Button("Check for keys on keychain?") {
                withAnimation {
                    if self.appState.searchAndImportFromKeychain() == false {
                        noKeysFoundFromSearchToast = true
                    }
                }
            }
        }
        .toast(isPresenting: $noKeysFoundFromSearchToast){
            AlertToast(displayMode: .banner(.slide), type: .regular,
                       title: "🥲 Sorry",
                       subTitle: "Unable to find any new keys in your keychain.",
                       style: AlertToast.AlertStyle.style())
        }
    }
    
    func delete(at offsets: IndexSet) {
        appState.remove(ownerKeyAt: offsets)
    }
    
    func add() {
        if validKey() {
            if appState.importNewKey(withPrivateKey: inputFieldText) {
                self.adding.toggle()
                self.focus.toggle()
            }
        }
    }
    
    func new() {
        _ = appState.addNewKey()
    }
    
    func validKey() -> Bool {
        return !inputFieldText.isEmpty
    }
}

struct KeysView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            KeysView()
                .environmentObject(AppState.shared)
        }
    }
}
