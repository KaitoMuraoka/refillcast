import Foundation
import SwiftData
@testable import refillcast

/// 通知の予約を記録するだけの偽物。
@MainActor
final class RecordingReminderScheduler: ReminderScheduling {
    private(set) var authorizationRequestCount = 0
    private(set) var rescheduled: [ReminderSource] = []
    private(set) var rescheduledAll: [[ReminderSource]] = []
    private(set) var cancelled: [UUID] = []

    func requestAuthorizationIfNeeded() { authorizationRequestCount += 1 }
    func reschedule(_ source: ReminderSource) { rescheduled.append(source) }
    func rescheduleAll(_ sources: [ReminderSource]) { rescheduledAll.append(sources) }
    func cancel(itemID: UUID) { cancelled.append(itemID) }
}

/// インメモリの ItemStore と、時刻を差し替えられる時計。
@MainActor
final class StoreFixture {
    let container: ModelContainer
    let reminders = RecordingReminderScheduler()
    var now: Date
    private(set) var store: ItemStore!

    init(now: Date = TestCalendar.date(2026, 11, 11, 10)) throws {
        self.now = now
        self.container = try ModelContainerFactory.make(inMemory: true)
        self.store = ItemStore(
            context: container.mainContext,
            reminders: reminders,
            calendar: TestCalendar.tokyo,
            now: { [unowned self] in self.now }
        )
    }

    func draft(
        _ name: String,
        cycleDays: Int = 30,
        purchasedAt: Date? = nil
    ) -> ItemDraft {
        ItemDraft(name: name, cycleDays: cycleDays, memo: "", initialPurchaseDate: purchasedAt)
    }
}
