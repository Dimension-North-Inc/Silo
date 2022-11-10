//
//  Bindings.swift
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
    }
    enum Action: Actions {
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
    }
}

// MARK: - Sample View
struct Bindings: View {
    @StateObject
    private var user = Store(UserReducer(), state: UserReducer.State())

    var body: some View {
        Form {
            TextField("Name", text: user.$name)
            Toggle(isOn: user.$isVerified) {
                Text("Is Verified")
            }
        }.padding()
    }
}

struct BindingActions_Previews: PreviewProvider {
    static var previews: some View {
        Bindings()
    }
}
