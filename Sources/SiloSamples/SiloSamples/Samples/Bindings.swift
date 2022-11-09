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
    enum Action: BindingActions {
        case binding(BindingValue<State>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            
            switch action {
            case let .binding(binding):
                binding.update(&state)

                switch binding {
                case \.$name:
                    print("validate user name")
                case \.$isVerified:
                    print("validate user isVerified")
                default:
                    break
                }
            }
            
            return .none
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
