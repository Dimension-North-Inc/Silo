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
        @BindingState var name: String = ""
        @BindingState var isVerified: Bool = false
        
        var accessCount: Int = 0
    }
    enum Action: Actions {
        case incrementAccessCount
    }

    var body: some Reducer<State, Action> {
        BindingReducer {
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
            case .incrementAccessCount:
                state.accessCount += 1
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
                Text("`BindingReducer` and `@BindingState` synthesize reducer actions corresponding to simple state updates.")
            }
            Section {
                TextField("Name", text: user.$name)
                Toggle(isOn: user.$isVerified) {
                    Text("Is Verified")
                }
                Text("\(user.accessCount)")
            }
            Section {
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
