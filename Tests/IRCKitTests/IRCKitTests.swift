import XCTest
@testable import IRCKit

final class IRCKitTests: XCTestCase {
    func testInit() {
        _ = IRCKit()
        XCTAssertTrue(true)
    }
}
