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
    @ObservedObject var settings: KlipSettings
    let onChangeHotkey: (HotkeyChoice) -> Void
    let onChangeLaunchAtLogin: (Bool) -> Void
    let onSettingsVisibilityChange: (Bool) -> Void
    let onSelect: (ClipboardItem) -> Void
    let onQuit: () -> Void
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @State private var showingSettings = false
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
                Text(showingSettings ? "Settings" : "Clipboard History")
                    .font(.headline)

                Spacer()

                Button {
                    showingSettings.toggle()
                } label: {
                    Image(systemName: showingSettings ? "chevron.left" : "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(showingSettings ? "Back to history" : "Settings")

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

            if let error = clipboardManager.errorMessage {
                HStack {
                    Text(error).font(.caption)
                    Spacer()
                    Button("Dismiss") { clipboardManager.errorMessage = nil }
                        .buttonStyle(.plain)
                }
                .foregroundStyle(.orange)
                .padding(8)
            }

            if showingSettings {
                settingsView
            } else {
                historyView
            }
        }
        .frame(width: 320, height: 400)
        .background(Color.clear)
        .onAppear {
            searchIsFocused = true
            selectedIndex = 0
        }
        .onChange(of: showingSettings) { showing in
            onSettingsVisibilityChange(showing)
            if !showing { searchIsFocused = true }
        }
        .onChange(
            of: searchText,
            perform: { _ in
                selectedIndex = 0
            }
        )
        .onChange(of: clipboardManager.items) { _ in
            selectedIndex = max(0, min(selectedIndex, filteredItems.count - 1))
        }
        .onReceive(NotificationCenter.default.publisher(for: .klipMoveSelection)) { notification in
            guard !showingSettings, !filteredItems.isEmpty,
                let direction = notification.userInfo?["direction"] as? String
            else { return }

            if direction == "down" {
                selectedIndex = min(selectedIndex + 1, filteredItems.count - 1)
            } else {
                selectedIndex = max(selectedIndex - 1, 0)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .klipConfirmSelection)) { _ in
            guard !showingSettings else { return }
            selectCurrentItem()
        }
    }

    private var historyView: some View {
        VStack(spacing: 0) {
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
                ScrollViewReader { proxy in
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
                                    HStack(spacing: 4) {
                                        row(for: item)
                                            .onTapGesture {
                                                selectedIndex = index
                                                onSelect(item)
                                            }
                                        Button {
                                            clipboardManager.togglePin(item)
                                        } label: {
                                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                        }
                                        .foregroundStyle(.secondary)
                                        .help(item.isPinned ? "Unpin" : "Pin")
                                        Button {
                                            clipboardManager.delete(item)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .foregroundStyle(.secondary)
                                        .help("Delete")
                                    }
                                    .buttonStyle(.plain)
                                    .id(item.id)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                index == selectedIndex
                                                    ? Color.accentColor.opacity(0.22) : .clear)
                                    )
                                }
                            }
                            .padding(10)
                        }
                    }
                    .onChange(of: selectedIndex, perform: { index in
                        guard filteredItems.indices.contains(index) else { return }
                        withAnimation(.easeInOut(duration: 0.12)) {
                            proxy.scrollTo(filteredItems[index].id, anchor: .center)
                        }
                    })
                }
            }
        }
    }

    private var settingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: onChangeLaunchAtLogin
                ))
                Text("macOS may require approval in Login Items.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Shortcut", selection: Binding(
                    get: { settings.hotkey },
                    set: onChangeHotkey
                )) {
                    ForEach(HotkeyChoice.allCases) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }
                Stepper(
                    "Recent items: \(settings.historyLimit)",
                    value: $settings.historyLimit, in: 5...200, step: 5
                )
                .onChange(of: settings.historyLimit) { _ in clipboardManager.applyHistoryLimit() }
                Text("Pinned items do not count toward this limit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Remove duplicate entries", isOn: $settings.deduplicate)
                    .onChange(of: settings.deduplicate) { enabled in
                        if enabled { clipboardManager.removeDuplicates() }
                    }
                Toggle("Save history between launches", isOn: Binding(
                    get: { settings.persistHistory },
                    set: { clipboardManager.setPersistence($0) }
                ))
                Text("Saved history is stored unencrypted on this Mac. Turning this off deletes the saved file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
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
