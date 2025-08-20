import AppStore

#if canImport(SwiftUI)
import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: AppStore
    @Binding var selection: UUID?

    var body: some View {
        List(selection: $selection) {
            ForEach(Array(store.state.buffers.values)) { buffer in
                Text(buffer.name).tag(buffer.id)
            }
        }
        .listStyle(.sidebar)
    }
}
#endif
