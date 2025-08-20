import AppStore

#if canImport(SwiftUI)
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: AppStore
    @Binding var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store, selection: $selection)
            VStack(spacing: 0) {
                TranscriptView(store: store, bufferID: selection)
                ComposerView()
            }
        }
    }
}
#endif
