<p align="center"><img src="https://github.com/Dimension-North-Inc/Silo/blob/main/Logo.svg?raw=true" width="33%"></p>


# Silo

A Flux inspired state container featuring composable Reducer types and a unified Reducer/Middleware async `Effect` system.

`Silo` is an evolution of our older state container: `Storage`, which more closely models Redux with `Store`, `Reducer`, and `Middleware` 
types playing roles similar to those you might encounter in a standard Redux environment. 

### Silo versus Storage - Benefits & Drawbacks

`Silo` has been designed from the ground-up to work in the new `async-await` world of Swift. It falls back on the `Combine` framework
where it needs to, but eschews that wherever it can to simplify the codebase. `Combine` plays a role in Apple's SwiftUI framework, so `Silo`
adopts it particularly in it's built-in SwiftUI support, but it otherwise minimizes dependency on the framework.

`Storage`, by comparison, was written prior to both `async-await` and `Combine`.

A recent addition to `Silo` originating in `Storage` is support for `UndoManager`. Its implementation in `Silo` has some limitations you should
carefully consider: undo/redo and async `Effect`s are dangerous when mixed. A storage container should support either async `Effect`s or 
`UndoManager`, but not both.

### Silo Components

`Silo` bundles two basic services that are meant to be used together - a state manager `Store`, and a dependency injectable type `Injectable`. 
These two services combine to provide a highly configurable, easily testable back-end for SwiftUI applications.

#### Store

The first and principle service `Silo` provides is a state container called `Store`. Customize the behaviour of your `Store` using a `Reducer` with
associated `State` and `Actions`. Trigger a state update by `dispatch`ing actions to the `Store`. Behaviours triggered by Actions are represented as
`Effects` which run asynchronously and dispatch new `Actions` as they run. 

`State` represents an application's configuration at some snapshot in time.

`Action` represents both user interactions as well as points in an application's lifecycle. A user's button tap which adds a TODO item to a list of TODOs 
can be modeled as an action. Similarly, application launch, a ticking timer, or the presentation of a new window can be modeled as actions. 

`Reducer` encapsulates application logic in a `reduce(state:action:)` function where `State` is modified and optional asynchronous `Effect`s are run:

```swift
struct Ticker: Reducer {
    struct State: States {
        var timer: String?
        var numberOfTicks: Int
    }
    enum Action: Actions {
        case tick
        case stopTicking
        case startTicking(timer: String)
    }
    func reduce(state: inout State, action: Action) -> Effect<Action>? {
        switch action {
        case .tick:
            if state.timer != nil {
                state.numberOfTicks += 1
            }
            return .none

        case .stopTicking:
            defer { state.timer = nil }
            return Effects.cancel(state.timer)

        case .startTicking(let timer):
            state.timer = timer
            return Effect.many {
                emit in
                while true {
                    try? await Task.sleep(for: .seconds(1))
                    emit(.tick)
                }
            }
            .cancelled(using: state.timer)
        }
    }
}
```

Silo reducers can be described either by a `reduce(state:action:)` function, or by a declarative `body` property. 
A reducer body declaration allows you to easily compose child reducers for either to-one or to-many parent-child 
relationships.

```swift
        // a reducer definition
        struct Parent: Reducer {
            // state managed by the reducer
            struct State: States {
                var foo: Int
                var bar: String
                
                var child: Child.State
            }
            // actions regognized by the reducer
            enum Action: Actions {
                case updateFoo(Int)
                case updateBar(String)
                
                case child(Child.Action)
            }
            
            
            // body property
            var body: some Reducer<State, Action> {
                // handle local state in a `Reduce` block
                Reduce {
                    state, action in
                    
                    switch action {
                    case let .updateFoo(value): state.foo = value
                    case let .updateBar(value): state.bar = value
                        
                    default: break
                    }
                    
                    return .none
                }
                
                // Child reducers are run for child state before local state
                ReduceChild(\.child, action: /Action.child) {
                    Child()
                }
            }
        }
```

`ReduceBindings` and the `@Bound` property wrapper generate synthetic actions used to reduce simple state updates:

```swift
    struct State: States {
        // synthesize update actions for properties marked `@Bound`
        @Bound var name: String = ""
        @Bound var isVerified: Bool = false
        
        var accessCount: Int = 0
    }
    
    // make actions conform to `BindingActions` with a `case binding(BindingAction<State>)` action
    enum Action: BindingActions {
        case incrementAccessCount
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        // reduce local state
        Reduce {
            state, action in
            switch action {
            case .incrementAccessCount: state.accessCount += 1
                
            default: break
            }
            
            return .none
        }
        
        // reduce local `@Bound` state
        ReduceBindings()
    }
```

**Undo Manager Support**

Actions dispatched to a store modify state. When dispatching actions, pass an `UndoManager` to mark the action as Undo/Redo-able. 
In SwiftUI applications, the active `UndoManager` instance can be accessed from the current `Environment`:

```swift
// MARK: - Sample View
struct UndoableActionsSample: View {
    @Environment(\.undoManager) private var undoManager

    @StateObject
    private var counter = Store(UndoableCounter(), state: UndoableCounter.State())
    
    var body: some View {
        Form {
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

```

**Projection**

Silo states are often optimized for quick access or normalized to remove data duplication, at the cost of 
understandability. To present state in a more understandable, task-specific way, create a `Projection` 
- a `ViewModel` style object that can be injected into SwiftUI Views. 

To make a store available for projection within child views, use the `.project(_:)` modifier within a parent SwiftUI view:

```swift
struct ParentView: View {
    struct ProjectedCounter: Feature {
        struct State: States {
            var value: Int = 0
        }
        enum Action: Actions {
            case increment
            case decrement
        }
        
        static var initial = State()
        
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

    // a store we want to project to child views
    var store = Store<ProjectedCounter>()

    var body: some View {
        MyTopLevelContainer()
        
            // project the store into child views
            .project(store)
    }
}
```

Create a store-backed view model by implementing the `Projection` protocol:

```swift
// Store-backed ViewModel
final class Stars: Projection, ObservableObject {
    @Published var stars: String = ""
    
    init(store: Store<ProjectedCounter>) {
        // cached to send actions
        self.store = store
        
        /// perform our mapping from state to view model state...
        store.states
            // pick out the integer value
            .map {
                $0.value
            }
            
            // ignore unrelated state updates
            .removeDuplicates()

            /// convert to a string of emoji stars`
            .map {
                value in String(repeating: "⭐️", count: value)
            }

            /// finally, assign to our `@Published `stars property
            .assign(to: &$stars)
    }

    private var store: Store<ProjectedCounter>

    func rateHigher() {
        store.dispatch(.increment)
    }
    func rateLower() {
        store.dispatch(.decrement)
    }
}
```

Within child views, use Silo's `Projected` view type to create and access
your view model:

```swift
struct ChildView: View {
    var body: some View {
        // inject our view model
        Projected(Stars.self) {
            model in 
            
            // the model is now accessible within the view
            VStack {
                Text(model.stars)
                Button(model.rateHigher) {
                    Label("Thumbs Up")
                }
                Button(model.rateLower) {
                    Label("Thumbs Down")
                }
            }
        }
    }
}
```

#### Injectable

Conceptually, an `Injectable` is a value  that you want to `inject` into other code at runtime, rather than hard code at compile time.
`Injectables` can be values, classes, or functions that - when injected into other code - cause that code to behave differently.

**Use Injectables to make your code more testable:**

Networking code that accesses a remote server in a running application can
be replaced by injecting a stub that doesn't actually access the remote server, but instead returns a predetermined result - either some data, or
a simulated networking failure. By controlling network responses, you can write tests to ensure your code can handle hard-to-reproduce
networking conditions and replies.

```swift
func processUsers() async throws {
    @Injected(API.getUsers) var getUsers
    let users = try await getUsers()
    //...
}
```
**Use Injectables to make using Xcode previews easier:**

Substitute data displayed in a running application with data meant to be displayed in an Xcode preview instead using an injectable.

```swift
struct ProductList_Previews: PreviewProvider {
    static var previews: some View {
        let _ = API.getProducts.register { query in
            return [
                Product("Beets"),
                Product("Fish"),
            ]
        }
        ProductList()
    }
}
```

**Use Injectables to make your applications more flexible:**

Specialize your code for particular users or marketplaces by injecting premium features in place of basic features in an in-app purchasable
application; or by injecting code that interacts with either the Apple App Store, or third party stores like Paddle, depending upon where the app is sold.

```swift
func enablePremiumFeatures() async throws {
    Features.gameModes.register {
        premiumGameModes()
    }
    Features.purchaseablePowerups.register { user in
        premiumPowerupsFor(user)
    }
    //...
}
```

### Testing

`Silo` includes the `Expect` package for more fluent test case expressions and several basic tests surrounding parent-child reducer relationships.
