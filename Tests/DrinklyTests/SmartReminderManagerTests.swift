import XCTest
@testable import Drinkly

final class SmartReminderManagerTests: XCTestCase {
    var manager: SmartReminderManager!

    override func setUp() {
        super.setUp()
        manager = SmartReminderManager()
        manager.resetAllReminders() // Ensure clean state
    }

    func testAddReminderAppearsInActiveList() {
        let reminder = SmartReminder(time: Date(), message: "Test Reminder", isEnabled: true)
        manager.addReminder(reminder)
        XCTAssertTrue(manager.reminders.contains(where: { $0.id == reminder.id }))
        XCTAssertTrue(manager.reminders.filter { $0.isEnabled }.contains(where: { $0.id == reminder.id }))
        XCTAssertFalse(manager.reminders.filter { !$0.isEnabled }.contains(where: { $0.id == reminder.id }))
    }

    func testToggleMovesReminderToDisabledList() {
        let reminder = SmartReminder(time: Date(), message: "Test Toggle", isEnabled: true)
        manager.addReminder(reminder)
        var updated = reminder
        updated.isEnabled = false
        manager.updateReminder(updated)
        XCTAssertFalse(manager.reminders.filter { $0.isEnabled }.contains(where: { $0.id == reminder.id }))
        XCTAssertTrue(manager.reminders.filter { !$0.isEnabled }.contains(where: { $0.id == reminder.id }))
    }

    func testToggleMovesReminderBackToActiveList() {
        let reminder = SmartReminder(time: Date(), message: "Test Toggle Back", isEnabled: false)
        manager.addReminder(reminder)
        var updated = reminder
        updated.isEnabled = true
        manager.updateReminder(updated)
        XCTAssertTrue(manager.reminders.filter { $0.isEnabled }.contains(where: { $0.id == reminder.id }))
        XCTAssertFalse(manager.reminders.filter { !$0.isEnabled }.contains(where: { $0.id == reminder.id }))
    }

    func testNoDuplicateOrLingeringReminders() {
        let reminder = SmartReminder(time: Date(), message: "No Duplicates", isEnabled: true)
        manager.addReminder(reminder)
        var updated = reminder
        updated.isEnabled = false
        manager.updateReminder(updated)
        updated.isEnabled = true
        manager.updateReminder(updated)
        let active = manager.reminders.filter { $0.isEnabled && $0.id == reminder.id }
        let disabled = manager.reminders.filter { !$0.isEnabled && $0.id == reminder.id }
        XCTAssertEqual(active.count + disabled.count, 1)
    }
} 