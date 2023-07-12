//
//  BindingsSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-11-08.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Reducer
struct UserReducer: Reducer {
    struct State: States {
        @Bound var name: String = ""
        @Bound var isVerified: Bool = false
        
        var accessCount: Int = 0
    }
    enum Action: BindingActions {
        case incrementAccessCount
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        ReduceBindings {
            state, action in
            
            /// an optional closure allows observation of binding updates...
            switch action.keyPath {
            case \.$name:       print("will update name: \(action.value)")
            case \.$isVerified: print("will update isVerified: \(action.value)")
            
            default:            break
            }
            
            /// return `true` to allow the  update, `false` otherwise
            return true
        }
        Reduce {
            state, action in
            switch action {
            case .incrementAccessCount: state.accessCount += 1
                
            case .binding:
                /// allow `ReduceBindings` to process the binding update
                break
            }
            
            return .none
        }
    }
}

// MARK: - Sample View
struct BindingsSample: View {
    @StateObject
    private var user = Store(UserReducer(), state: UserReducer.State())

    var body: some View {
        Form {
            Section {
                Text("`ReduceBindings` and the `@Bound` property wrapper generate synthetic actions used to reduce simple state updates.")
            }
            Section("Implicit Bindings Action Dispatch") {
                TextField("Name", text: user.$name)
                Toggle(isOn: user.$isVerified) {
                    Text("Is Verified")
                }
            }
            Section("Explicit Action Dispatch via `dispatch(_:)`") {
                Text("\(user.accessCount)")
                Button("Increment Access Count") {
                    user.dispatch(.incrementAccessCount)
                }
            }
        }
        .formStyle(GroupedFormStyle())
    }
}

struct BindingActions_Previews: PreviewProvider {
    static var previews: some View {
        BindingsSample()
    }
}
