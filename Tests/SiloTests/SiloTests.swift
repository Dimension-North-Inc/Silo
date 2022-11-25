import XCTest
import Expect

@testable import Silo

final class SiloTests: XCTestCase {
    
    struct Foo: Reducer {
        struct State: States {
            var foo: Int
            var bar: String
            var baz: Baz.State
        }
        enum Action: Actions {
            case updateFoo(Int)
            case updateBar(String)
        }
        var body: some Reducer<State, Action> {
            Reduce {
                state, action in
                
                switch action {
                case let .updateFoo(value): state.foo = value
                case let .updateBar(value): state.bar = value
                }
                
                return .none
            }
            ReduceChild(state: \.baz, reducer: Baz())
        }
    }
    
    struct Baz: Reducer {
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
    
    
    func testExample() throws {
        let store = Store(
            Foo(),
            state: Foo.State(
                foo: 1,
                bar: "A",
                baz: Baz.State(
                    baz: true,
                    buq: 3.14
                )
            )
        )
        
        expect(store.state.value.baz.buq) == 3.14

        store.dispatch(Baz.Action.updateBuq(3))
        expect(store.state.value.baz.buq) == 3
    }
}
