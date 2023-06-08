import XCTest
import Expect

@testable import Silo

final class ReducerTests: XCTestCase {
    
    func testReduceChild() throws {
        struct Parent: Reducer {
            struct State: States {
                var foo: Int
                var bar: String
                
                var child: Child.State
            }
            enum Action: Actions {
                case updateFoo(Int)
                case updateBar(String)
                
                case child(Child.Action)
            }
            var body: some Reducer<State, Action> {
                Reduce {
                    state, action in
                    
                    switch action {
                    case let .updateFoo(value): state.foo = value
                    case let .updateBar(value): state.bar = value
                        
                    default: break
                    }
                    
                    return .none
                }
                ReduceChild(\.child, action: /Action.child) {
                    return Child()
                }
            }
        }
        
        struct Child: Reducer {
            struct State: States {
                var baz: Bool
                var buq: Float
            }
            
            enum Action: Actions {
                case updateBaz(Bool)
                case updateBuq(Float)
            }
            
            var body: some Reducer<State, Action> {
                Reduce {
                    state, action in
                    switch action {
                    case let .updateBaz(value): state.baz = value
                    case let .updateBuq(value): state.buq = value
                    }
                    
                    return .none
                }
            }
        }

        let store = Store(
            Parent(),
            state: Parent.State(
                foo: 1,
                bar: "A",
                
                child: Child.State(
                    baz: true,
                    buq: 3.14
                )
            )
        )
        
        // preconditions
        expect(store.foo) == 1
        expect(store.child.buq) == 3.14

        // update local state
        store.dispatch(.updateFoo(2))
        expect(store.foo) == 2
        
        // update child state
        store.dispatch(.child(.updateBuq(3)))
        expect(store.child.buq) == 3
    }
    
    func testReduceChildren() throws {
        struct Parent: Reducer {
            struct State: States {
                var foo: Int
                var bar: String
                
                var children: IdentifiedArrayOf<Child.State>
            }
            
            enum Action: Actions {
                case updateFoo(Int)
                case updateBar(String)
                
                case child(Child.State.ID, Child.Action)
            }
            
            var body: some Reducer<State, Action> {
                Reduce {
                    state, action in
                    switch action {
                    case let .updateFoo(value): state.foo = value
                    case let .updateBar(value): state.bar = value
                    
                    default:
                        break
                    }
                    
                    return .none
                }
                ReduceChildren(\.children, action: /Action.child) {
                    return Child()
                }
            }
        }
        
        struct Child: Reducer {
            struct State: States, Identifiable {
                var id: Int
                var buq: Float
            }
            
            enum Action: Actions {
                case updateBuq(Float)
            }
            
            var body: some Reducer<State, Action> {
                Reduce {
                    state, action in
                    switch action {
                    case let .updateBuq(value): state.buq = value
                    }
                    
                    return .none
                }
            }
        }
        
        
        let store = Store(
            Parent(),
            state: Parent.State(
                foo: 1,
                bar: "A",
                
                children: [
                    Child.State(id: 1, buq: 1.1),
                    Child.State(id: 2, buq: 2.2),
                    Child.State(id: 3, buq: 3.3),
                ]
            )
        )

        // preconditions
        expect(store.foo) == 1
        expect(store.children[id: 1]?.buq) == 1.1
        expect(store.children[id: 2]?.buq) == 2.2
        expect(store.children[id: 3]?.buq) == 3.3

        // update local state
        store.dispatch(.updateFoo(2))
        expect(store.foo) == 2
        
        // update child state
        store.dispatch(.child(2, .updateBuq(22.22)))
        expect(store.children[id: 1]?.buq) == 1.1
        expect(store.children[id: 2]?.buq) == 22.22
        expect(store.children[id: 3]?.buq) == 3.3
    }
}
