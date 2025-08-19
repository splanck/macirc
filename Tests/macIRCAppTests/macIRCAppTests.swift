import XCTest
@testable import macIRCApp

final class MacIRCAppTests: XCTestCase {
    func testMainRuns() async {
        await MacIRCApp.main()
        XCTAssertTrue(true)
    }
}
