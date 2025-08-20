import AppStore

#if canImport(SwiftUI)
import SwiftUI

@main
struct MacIRCApp: App {
    @StateObject private var store = AppStore()
    @State private var selectedBuffer: UUID?

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, selection: $selectedBuffer)
        }
    }
}
#else
@main
struct MacIRCApp {
    static func main() {
        print("SwiftUI not supported on this platform")
    }
}
#endif
