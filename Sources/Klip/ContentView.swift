import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    static let klipMoveSelection = Notification.Name("KlipMoveSelection")
    static let klipConfirmSelection = Notification.Name("KlipConfirmSelection")
}

/// Compact list of clipboard history items shown inside the floating panel.
struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    let onSelect: (ClipboardItem) -> Void
    let onQuit: () -> Void
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var searchIsFocused: Bool

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
                    .focused($searchIsFocused)
                    .onSubmit(selectCurrentItem)

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
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) {
                                index, item in
                                row(for: item)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                index == selectedIndex
                                                    ? Color.accentColor.opacity(0.22) : .clear)
                                    )
                                    .onTapGesture {
                                        selectedIndex = index
                                        onSelect(item)
                                    }
                            }
                        }
                        .padding(10)
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
        .background(Color.clear)
        .onAppear {
            searchIsFocused = true
            selectedIndex = 0
        }
        .onChange(
            of: searchText,
            perform: { _ in
                selectedIndex = 0
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: .klipMoveSelection)) { notification in
            guard !filteredItems.isEmpty,
                let direction = notification.userInfo?["direction"] as? String
            else { return }

            if direction == "down" {
                selectedIndex = min(selectedIndex + 1, filteredItems.count - 1)
            } else {
                selectedIndex = max(selectedIndex - 1, 0)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .klipConfirmSelection)) { _ in
            selectCurrentItem()
        }
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

    private func selectCurrentItem() {
        guard filteredItems.indices.contains(selectedIndex) else { return }
        onSelect(filteredItems[selectedIndex])
    }
}
