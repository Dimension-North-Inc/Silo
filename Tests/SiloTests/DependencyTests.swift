import XCTest
import Expect

@testable import Silo

final class DependencyTests: XCTestCase {
    func testUUIDGeneratorCanReturnContantUUIDs() {
        let uuid = UUID()
        DependencyValues.pushing {
            $0.uuid = .constant(uuid)
        } execute: {
            @Dependency(\.uuid) var constant;
            
            expect(constant()) == uuid
            expect(constant()) == uuid
        }
    }

    func testUUIDGeneratorCanReturnSequentialUUIDs() {
        DependencyValues.pushing {
            $0.uuid = .sequential
        } execute: {
            @Dependency(\.uuid) var sequential;
            
            expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000000"
            expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000001"
            expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000002"
            expect(sequential().uuidString) == "00000000-0000-0000-0000-000000000003"
        }
    }
    
    func testDateGeneratorCanReturnConstantDates() {
        let date = Date()
        DependencyValues.pushing {
            $0.date = .constant(date)
        } execute: {
            @Dependency(\.date) var constant;
            
            expect(constant()) == date
            expect(constant()) == date
        }
    }
}
