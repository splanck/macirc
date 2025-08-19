import XCTest
@testable import NetKit

final class NetKitTests: XCTestCase {
    func testInit() {
        _ = NetKit()
        XCTAssertTrue(true)
    }
}
