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
            
            // no side effects
            return .none
        }
    }
}

// MARK: - View Model
final class Stars: Projection, ObservableObject {
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

    func dispatch(_ action: ProjectedCounter.Action) {
        store.dispatch(action)
    }
}

// MARK: - Sample View
struct ProjectionSample: View {
    var body: some View {
        Form {
            Section {
                Text(
                        """
                        ViewModel objects based on Silo Stores
                        can be introduced into SwiftUI Views using
                        the `Projected` view type.
                        
                        Create `Projections` conforming types to
                        present Silo `Store` instances registered
                        by parent views.
                        """
                )
            }
            Section {
                Projected(Stars.self) {
                    model in
                    
                    Text("\(model.stars)")
                    Button("Increment") {
                        model.dispatch(.increment)
                    }
                    Button("Decrement") {
                        model.dispatch(.decrement)
                    }
                }
            }
        }
        .formStyle(GroupedFormStyle())
    }
}

#Preview {
    ProjectionSample()
}
