import XCTest
import Expect

@testable import Silo

final class SiloTests: XCTestCase {
    
    struct Foo: Reducer {
        struct State: States {
            var foo: Int
            var bar: String
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
        }
    }
    
    struct Baz: Reducer {
        struct State: States {
            var id = UUID()
            var baz: Bool
            var buq: Float
        }
        
        enum Action: Actions {
            case updateBaz(UUID, Bool)
            case updateBuq(UUID, Float)
        }
        
        var body: some Reducer<State, Action> {
            Reduce {
                state, action in
                switch action {
                case let .updateBaz(id, value) where id == state.id:
                    state.baz = value
                case let .updateBuq(id, value) where id == state.id:
                    state.buq = value
                default: break
                }
                
                return .none
            }
        }
    }
    
    
    func testExample() throws {
        expect(true) == true
    }
}
