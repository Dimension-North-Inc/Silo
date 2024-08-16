import XCTest
import Testing

@testable import Silo

@Suite
struct BuiltinInjectables {
    @Test
    func testUUIDGeneratorCanReturnSequentialUUIDs() {
        Builtins.uuid.register { .sequential }
        
        @Injected(Builtins.uuid) var sequential;
        
        #expect(sequential().uuidString == "00000000-0000-0000-0000-000000000000")
        #expect(sequential().uuidString == "00000000-0000-0000-0000-000000000001")
        #expect(sequential().uuidString == "00000000-0000-0000-0000-000000000002")
        #expect(sequential().uuidString == "00000000-0000-0000-0000-000000000003")
    }
    
    @Test
    func testUUIDGeneratorCanReturnConstantUUIDs() {
        let uuid = UUID()
        
        Builtins.uuid.register { .constant(uuid) }
        
        @Injected(Builtins.uuid) var constant;
        
        #expect(constant() == uuid)
        #expect(constant() == uuid)
    }
    
    @Test
    func testDateGeneratorCanReturnConstantDates() {
        let date = Date()
        
        Builtins.date.register { .constant(date) }
        
        @Injected(Builtins.date) var constant;
        
        #expect(constant() == date)
        #expect(constant() == date)
    }
}
