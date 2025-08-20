import AppStore

#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

struct TranscriptView: NSViewRepresentable {
    @ObservedObject var store: AppStore
    var bufferID: UUID?

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isRichText = false
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        if let id = bufferID, let topic = store.state.topics[id]?.text {
            nsView.string = topic
        } else {
            nsView.string = ""
        }
    }
}
#endif
