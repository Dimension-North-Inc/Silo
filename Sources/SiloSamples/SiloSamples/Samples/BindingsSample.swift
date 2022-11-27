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
        @Bindable var name: String = ""
        @Bindable var isVerified: Bool = false
        
        var accessCount: Int = 0
    }
    enum Action: BindableAction {
        case incrementAccessCount
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        ReduceBindings {
            state, action in
            switch action.keyPath {
            case \.$name:       print("will update name: \(action.value)")
            case \.$isVerified: print("will update isVerified: \(action.value)")
            
            default:            break
            }
            
            return true
        }
        Reduce {
            state, action in
            switch action {
            case .incrementAccessCount: state.accessCount += 1
                
            default: break
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
                Text("`ReduceBindings` and `@Bindable` synthesize reducer actions corresponding to simple state updates.")
            }
            Section("Binding-Generated Actions") {
                TextField("Name", text: user.$name)
                Toggle(isOn: user.$isVerified) {
                    Text("Is Verified")
                }
            }
            Section("`.dispatch`-Generated Actions") {
                Text("\(user.accessCount)")
                Button("Increment Access Count") {
                    user.dispatch(.incrementAccessCount)
                }
            }
        }
    }
}

struct BindingActions_Previews: PreviewProvider {
    static var previews: some View {
        BindingsSample()
    }
}
