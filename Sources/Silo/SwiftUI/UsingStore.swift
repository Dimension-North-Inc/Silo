//
//  SwiftUIView.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-16.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import SwiftUI

/// A View used to observe and update on store state updates.
///
/// Views with simple underyling stores may opt ot observe their stores directly as `@ObservableObject`s,
/// On each update of said stores, the entire view will be recalculated and redisplayed. For views with more complex
/// stores containing a large amount of state, use `UsingStore` to limit view updates based on store substate changes.
///
public struct UsingStore<Reducer, Value, Content>: View where Reducer: Silo.Reducer, Content: View {
    private var store: Store<Reducer>
    private let isEqual: (Value, Value) -> Bool
    private let keyPath: KeyPath<Store<Reducer>, Value>

    private let content: (Value) -> Content

    @State
    private var value: Value
        
    public var body: some View {
        content(value)
        // on store value update, reassign `value`
            .onReceive(store.state.$container) {
                _ in
                
                let v0 = value
                let v1 = store[keyPath: keyPath]
                
                if !isEqual(v0, v1) {
                    value = v1
                }
            }
    }
    
    /// Initializes the view to display substate `keyPath` of `store` on update.
    /// The comparison function `isEqual` is used to determine whether an update has occurred.
    /// - Parameters:
    ///   - store: a store
    ///   - keyPath: a keypath to store substate
    ///   - isEqual: a function used to determine whether substate has changed
    ///   - content: a view used to display the substate.
    public init(_ store: Store<Reducer>, keyPath: KeyPath<Store<Reducer>, Value>, isEqual: @escaping(Value, Value) -> Bool, @ViewBuilder content: @escaping (Value) -> Content) {
        self.store   = store
        self.keyPath = keyPath
        self.isEqual = isEqual

        self.content = content

        self._value  = State(initialValue: store[keyPath: keyPath])
    }

    /// Initializes the view to display substate `keyPath` of `store` on update.
    /// - Parameters:
    ///   - store: a store
    ///   - keyPath: a keypath to store substate
    ///   - isEqual: a function used to determine whether substate has changed
    ///   - content: a view used to display the substate.
    public init(_ store: Store<Reducer>, keyPath: KeyPath<Store<Reducer>, Value>, @ViewBuilder content: @escaping (Value) -> Content) where Value: Equatable {
        self.store   = store
        self.keyPath = keyPath
        self.isEqual = { v0, v1 in v0 == v1 }

        self.content = content

        self._value  = State(initialValue: store[keyPath: keyPath])
    }

}


struct UsingStore_Previews: PreviewProvider {
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
    
    static let store = Store<DoubleCounter>()
    
    static var previews: some View {
        Form {
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
