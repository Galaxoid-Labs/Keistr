//
//  RelaysView.swift
//  Keistr
//
//  Created by Jacob Davis on 2/27/23.
//

import SwiftUI
import Setting

struct RelaysView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var inputFieldText = ""
    @State private var adding = false
    @FocusState private var focus: Bool
    
    var relays: [Relay] {
        return appState.relays
    }
    
    var body: some View {
        List {
            
            if adding {
                Section {
                    TextField("wss://...", text: $inputFieldText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onSubmit({
                            self.add()
                        })
                        .focused($focus)
                }
            }
            
            if relays.count == 0 && self.adding == false {
                
                LazyVStack {
                    Button(action: {
                        withAnimation {
                            self.adding.toggle()
                            self.focus.toggle()
                        }
                    }) {
                        Text("Add Relay")
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
            } else {
                
                Section {
                    ForEach(relays) { relay in
                        HStack(alignment: .center) {
                            Circle()
                                .frame(width: 8)
                                .foregroundColor(.green)
                            Text(relay.url)
                            Spacer()
                        }
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
                
                if adding && validUrl() {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            withAnimation {
                                self.add()
                            }
                        }) {
                           Image(systemName: "checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!validUrl())
                    }
                }

            } else if relays.count > 0 {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        withAnimation {
                            self.adding.toggle()
                            self.focus.toggle()
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }

        }
        .navigationTitle("Relays")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func delete(at offsets: IndexSet) {
        appState.remove(relayAt: offsets)
    }
    
    func add() {
        if validUrl() {
            if let relay = Relay(url: inputFieldText) {
                appState.add(relay: relay)
                inputFieldText = ""
                self.adding.toggle()
                self.focus.toggle()
            }
        }
    }
    
    func validUrl() -> Bool {
        if inputFieldText.validSocketURL() {
            if !relays.contains(where: { $0.url == inputFieldText }) {
                return true
            }
        }
        return false
    }
}

struct RelaysView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RelaysView()
                .environmentObject(AppState.shared.initPreview())
        }
    }
}
