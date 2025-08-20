#if canImport(SwiftUI)
import SwiftUI

struct ComposerView: View {
    @State private var text = ""

    var body: some View {
        TextField("Message", text: $text)
            .textFieldStyle(.roundedBorder)
            .padding()
    }
}
#endif
