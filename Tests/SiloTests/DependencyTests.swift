import XCTest
import Expect

@testable import Silo

final class DependencyTests: XCTestCase {
    func testUUIDGeneratorCanReturnContantUUIDs() {
        let uuid = UUID()
        
        Builtins.uuid.register(factory: .constant(uuid))
        
        @Injected(Builtins.uuid) var constant;
        
        expect(constant()) == uuid
        expect(constant()) == uuid
    }

    func testUUIDGeneratorCanReturnSequentialUUIDs() {
        Builtins.uuid.register(factory: .sequential)
        
        @Injected(Builtins.uuid) var sequential;
        
        expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000000"
        expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000001"
        expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000002"
        expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000003"
    }
    
    func testDateGeneratorCanReturnConstantDates() {
        let date = Date()
        
        Builtins.date.register(factory: .constant(date))
        
        @Injected(Builtins.date) var constant;
        
        expect(constant()) == date
        expect(constant()) == date
    }
}
