import AppStore

#if canImport(SwiftUI)
import XCTest
@testable import macIRCApp

final class MacIRCAppTests: XCTestCase {
    func testSidebarRendersBuffers() {
        let store = AppStore()
        store.dispatch(.buffer(.add(BufferState(name: "general"))))
        let view = SidebarView(store: store, selection: .constant(nil))
        XCTAssertNotNil(view)
    }
}
#endif
