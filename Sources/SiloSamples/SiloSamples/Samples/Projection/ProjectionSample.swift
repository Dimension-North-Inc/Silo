//
//  ProjectionSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 09/26/23.
//  Copyright © 2023 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Reducer
struct ProjectedCounter: Reducer {
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
            
            if state.value < 0 { state.value = 0 }
            
            // no side effects
            return .none
        }
    }
}

// MARK: - Projection
final class Stars: Projection, ObservableObject {
    @Published var count: Int = 1 {
        didSet {
            if count < 1 { count = 1 }
        }
    }
    @Published var stars: String = ""
    
    init(store: Store<ProjectedCounter>) {
        /// caching this for the `dispatch` method
        self.store = store
        
        /// perform our mapping from state to view model state...
        store.states
            .map {
                /// pick out the integer value
                $0.value
            }
            .map {
                /// convert to a string of emoji stars`
                value in String(repeating: "⭐️", count: value)
            }
            .removeDuplicates()
            /// finally, assign to our `@Published `stars property
            .assign(to: &$stars)

    }

    private var store: Store<ProjectedCounter>

    func thumbsUp() {
        dispatch(count, .increment)
    }
    func thumbsDown() {
        dispatch(count, .decrement)
    }
    
    private func dispatch(
        _ count: Int, 
        _ action: ProjectedCounter.Action
    ) {
        for _ in 0..<count {
            store.dispatch(action)
        }
    }
}

// MARK: - Sample View
struct ProjectionSample: View {
    var body: some View {
        Projected(Stars.self) {
            $model in
            Form {
                Section {
                    Text(
                    """
                    A `Projection` presents a Silo `Store` in some purpose-built way, tailored to a particular view. Consider it the Silo equivalent of a `ViewModel` type.
                    
                    Projections can be introduced into SwiftUI Views using the `Projected` view type:
                    
                    `Projected(Stars.self) { $projection in ... }`
                    
                    To make a Store accessible within child views using the `Projected` view type, `project(_:)` the store inside some parent view:
                    
                    `parentView.project(myStore)`
                    """
                    )
                }
                Section {
                    Text("\(model.stars)")
                    
                    Button("Thumbs Up", action: model.thumbsUp)
                    Button("Thumbs Down", action: model.thumbsDown)

                    Stepper(
                        "^[\(model.count) Thumb](inflect: true) At A Time",
                        value: $model.count
                    )
                }
            }
            .formStyle(GroupedFormStyle())
        }
    }
}

#Preview {
    ProjectionSample()
}
