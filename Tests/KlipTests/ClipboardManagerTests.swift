import Foundation
import XCTest
@testable import Klip

final class ClipboardManagerTests: XCTestCase {
    private var directory: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: KlipSettings!
    private var manager: ClipboardManager!

    override func setUpWithError() throws {
        suiteName = "KlipTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        settings = KlipSettings(defaults: defaults)
        settings.historyLimit = 2
        manager = ClipboardManager(settings: settings, store: HistoryStore(directory: directory))
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
    }

    func testPinnedItemsSurviveLimitAndCanBeDeleted() throws {
        manager.insert(.text("first"))
        manager.togglePin(try XCTUnwrap(manager.items.first))
        manager.insert(.text("second"))
        manager.insert(.text("third"))
        manager.insert(.text("fourth"))

        XCTAssertEqual(manager.items.map(\.content), [.text("first"), .text("fourth"), .text("third")])
        XCTAssertTrue(manager.items[0].isPinned)
        manager.delete(manager.items[0])
        XCTAssertEqual(manager.items.map(\.content), [.text("fourth"), .text("third")])
    }

    func testDeduplicationPreservesPinnedEntryAndMovesRecentCopy() throws {
        settings.deduplicate = true
        manager.insert(.text("pinned"))
        manager.togglePin(try XCTUnwrap(manager.items.first))
        manager.insert(.text("other"))
        manager.insert(.text("pinned"))
        XCTAssertEqual(manager.items.map(\.content), [.text("pinned"), .text("other")])

        manager.insert(.text("new"))
        manager.insert(.text("other"))
        XCTAssertEqual(manager.items.map(\.content), [.text("pinned"), .text("other"), .text("new")])
    }

    func testOptInPersistenceRestoresAndDeletesHistoryWhenDisabled() throws {
        manager.insert(.text("saved"))
        manager.togglePin(try XCTUnwrap(manager.items.first))
        manager.setPersistence(true)
        XCTAssertTrue(settings.persistHistory)

        let restored = ClipboardManager(settings: settings, store: HistoryStore(directory: directory))
        XCTAssertEqual(restored.items, manager.items)
        restored.setPersistence(false)
        XCTAssertFalse(settings.persistHistory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("history.json").path))
        XCTAssertEqual(restored.items.count, 1)
    }

    func testRemoveExistingDuplicatesPrefersPinnedEntry() throws {
        settings.historyLimit = 3
        manager.insert(.text("same"))
        manager.insert(.text("different"))
        manager.insert(.text("same"))
        manager.togglePin(try XCTUnwrap(manager.items.last))
        manager.removeDuplicates()
        XCTAssertEqual(manager.items.map(\.content), [.text("same"), .text("different")])
        XCTAssertTrue(manager.items[0].isPinned)
    }

    func testFailedPersistenceDoesNotEnableSaving() throws {
        try Data().write(to: directory)
        manager.setPersistence(true)
        XCTAssertFalse(settings.persistHistory)
        XCTAssertNotNil(manager.errorMessage)
    }

    func testCorruptHistoryIsNotOverwritten() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("history.json")
        let invalid = Data("invalid".utf8)
        try invalid.write(to: file)
        settings.persistHistory = true

        let restored = ClipboardManager(settings: settings, store: HistoryStore(directory: directory))
        XCTAssertNotNil(restored.errorMessage)
        restored.insert(.text("new"))
        XCTAssertEqual(try Data(contentsOf: file), invalid)
    }
}
