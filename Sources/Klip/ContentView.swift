import AppKit
import SwiftUI

/// Compact list of clipboard history items shown inside the floating panel.
struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    let onSelect: (ClipboardItem) -> Void
    let onQuit: () -> Void
    @State private var searchText = ""

    private var filteredItems: [ClipboardItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clipboardManager.items }

        return clipboardManager.items.filter { item in
            guard case .text(let text) = item.content else { return false }
            return text.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.headline)

                Spacer()

                Button(action: onQuit) {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Quit Klip")
            }
            .padding(.top, 12)
            .padding(.bottom, 6)
            .padding(.horizontal, 12)

            Divider()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search clipboard", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            if clipboardManager.items.isEmpty {
                Spacer()
                Text("No items yet")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    // Vertical spacing here is the margin between entries.
                    if filteredItems.isEmpty {
                        Text("No matching items")
                            .foregroundStyle(.secondary)
                            .padding(.top, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredItems) { item in
                                row(for: item)
                                    .onTapGesture { onSelect(item) }
                            }
                        }
                        .padding(10)
                    }
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
