//
//  UndoableActionsSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2023-01-22.
//  Copyright © 2023 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Reducer
struct UndoableCounter: Reducer {
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
struct UndoableActionsSample: View {
    @Environment(\.undoManager) private var undoManager

    @StateObject
    private var counter = Store(UndoableCounter(), state: UndoableCounter.State())
    
    var body: some View {
        Form {
            Section {
                Text(
                    """
                    Dispatching actions and passing an `UndoManager` registers the resulting state updates as undoable. The `UndoManager` to pass into the dispatch function can be taken from the current SwiftUI `Environment`.
                    
                    When undoable actions are dispatched, Mac OS Undo and Redo menus become accessible and activated.
                    """
                )
            }
            Section {
                Text("\(counter.value)")
                Button("Increment") {
                    /// mark action as `undoable`
                    counter.dispatch(.increment, undoable: undoManager)
                }
                Button("Decrement") {
                    /// mark action as `undoable`
                    counter.dispatch(.decrement, undoable: undoManager)
                }
            }
        }
        .formStyle(GroupedFormStyle())
    }
}

struct UndoableActionsSample_Previews: PreviewProvider {
    static var previews: some View {
        UndoableActionsSample()
    }
}
