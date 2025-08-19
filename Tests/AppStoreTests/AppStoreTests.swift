import XCTest
@testable import AppStore

final class AppStoreTests: XCTestCase {
    func testBufferReducerAddsBuffer() {
        var state = [UUID: BufferState]()
        let buffer = BufferState(name: "#swift")
        buffersReducer(state: &state, action: .add(buffer))
        XCTAssertEqual(state[buffer.id]?.name, "#swift")
    }

    func testStoreDispatchesActions() {
        let store = AppStore()
        let buffer = BufferState(name: "#test")
        store.dispatch(.buffer(.add(buffer)))
        XCTAssertEqual(store.state.buffers[buffer.id], buffer)
    }
}
