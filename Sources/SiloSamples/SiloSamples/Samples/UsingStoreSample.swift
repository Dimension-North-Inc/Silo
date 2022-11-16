//
//  UsingStoreSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-11-16.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Reducer
struct DoubleCounter: Feature {
    struct State: States {
        var value: Int = 0
        var value2: Int = 10
    }
    enum Action: Actions {
        case increment
        case decrement
        
        case increment2
        case decrement2
    }
    
    init() {
    }
    static var initial: State {
        State()
    }

    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            
            switch action {
            case .increment:  state.value  += 1
            case .decrement:  state.value  -= 1
                
            case .increment2: state.value2 += 1
            case .decrement2: state.value2 -= 1
            }
            
            return .none
        }
    }
}

// MARK: - Sample View
struct UsingStoreSample: View {
    private var store = Store<DoubleCounter>()
    
    var body: some View {
        Form {
            Section {
                Text("`UsingStore` limits view updates based on store substate changes. Optimize complex views with one or more `UsingStore` views.")
            }
            Section {
                UsingStore(store, keyPath: \.value) {
                    value in
                    Text("\(value)")
                }
            }
            Section("Only Updates Above") {
                Button("Increment", action: { store.dispatch(.increment) })
                Button("Decrement", action: { store.dispatch(.decrement) })
            }
            
            Section {
                UsingStore(store, keyPath: \.value2) {
                    value in
                    Text("\(value)")
                }
            }
            Section("Only Updates Above") {
                Button("Increment", action: { store.dispatch(.increment2) })
                Button("Decrement", action: { store.dispatch(.decrement2) })
            }

        }
    }
}

struct UsingStoreSample_Previews: PreviewProvider {
    static var previews: some View {
        UsingStoreSample()
    }
}
