import AppKit
import SwiftUI

/// Compact list of clipboard history items shown inside the floating panel.
struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    let onSelect: (ClipboardItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Clipboard History")
                .font(.headline)
                .padding(.top, 12)
                .padding(.bottom, 6)

            Divider()

            if clipboardManager.items.isEmpty {
                Spacer()
                Text("No items yet")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    // Vertical spacing here is the margin between entries.
                    VStack(spacing: 8) {
                        ForEach(clipboardManager.items) { item in
                            row(for: item)
                                .onTapGesture { onSelect(item) }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(width: 320, height: 400)
        .background(Color.clear)
    }

    @ViewBuilder
    private func row(for item: ClipboardItem) -> some View {
        Group {
            switch item.content {
            case .text(let text):
                Text(text)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

            case .image(let data):
                if let nsImage = NSImage(data: data) {
                    HStack {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)
                        Spacer(minLength: 0)
                    }
                } else {
                    Text("Image")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
        )
        .contentShape(Rectangle())
    }
}
