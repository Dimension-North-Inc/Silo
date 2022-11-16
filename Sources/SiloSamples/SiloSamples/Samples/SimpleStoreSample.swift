//
//  SimpleStoreSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-11-06.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Reducer
struct Counter: Reducer {
    struct State: States {
        var value: Int = 0
    }
    enum Action: Actions {
        case increment
        case decrement
    }
    
    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            
            switch action {
            case .increment: state.value += 1
            case .decrement: state.value -= 1
            }
            
            // no side effects
            return .none
        }
    }
}

// MARK: - Sample View
struct SimpleStoreSample: View {
    @StateObject
    private var counter = Store(Counter(), state: Counter.State())
    
    var body: some View {
        Form {
            Section {
                Text("`Store` objects declared `@StateObject` drive view updates directly.")
            }
            Section {
                Text("\(counter.value)")
                Button {
                    counter.dispatch(.increment)
                } label: {
                    Text("Increment")
                }
                Button {
                    counter.dispatch(.decrement)
                } label: {
                    Text("Decrement")
                }
            }
        }
    }
}

struct ObservableStore_Previews: PreviewProvider {
    static var previews: some View {
        SimpleStoreSample()
    }
}
