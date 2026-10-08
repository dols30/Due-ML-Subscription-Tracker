//
//  SubscriptionTests.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import XCTest

@testable import Due

final class SubscriptionTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testMonthEndDoesNotDrift() {
        let item = Subscription(name: "Plan", price: 10, billingDate: date(2026, 1, 31))
        XCTAssertEqual(
            item.nextCharge(after: date(2026, 2, 1), calendar: calendar), date(2026, 2, 28))
        XCTAssertEqual(
            item.nextCharge(after: date(2026, 3, 1), calendar: calendar), date(2026, 3, 31))
        let events = item.events(
            in: DateInterval(start: date(2026, 2, 1), end: date(2026, 5, 1)), calendar: calendar)
        XCTAssertEqual(events, [date(2026, 2, 28), date(2026, 3, 31), date(2026, 4, 30)])
    }

    func testLeapYearAnnualBilling() {
        let item = Subscription(
            name: "Annual", price: 120, cycle: .yearly, billingDate: date(2024, 2, 29))
        XCTAssertEqual(
            item.nextCharge(after: date(2025, 1, 1), calendar: calendar), date(2025, 2, 28))
        XCTAssertEqual(
            item.nextCharge(after: date(2028, 1, 1), calendar: calendar), date(2028, 2, 29))
    }

    func testExpiredTrialRequiresReview() {
        let item = Subscription(
            name: "Trial", price: 20, billingDate: date(2026, 9, 29), status: .trial)
        XCTAssertEqual(item.daysRemaining(at: date(2026, 10, 2), calendar: calendar), -3)
        XCTAssertEqual(item.status, .trial)
        XCTAssertTrue(Money.totals([item]).isEmpty)
    }

    func testCurrenciesAndAnnualNormalization() {
        let items = [
            Subscription(name: "Monthly", price: Decimal(string: "5.99")!, billingDate: .now),
            Subscription(name: "Yearly", price: 96, cycle: .yearly, billingDate: .now),
            Subscription(name: "Euro", price: 12, currency: "EUR", billingDate: .now),
            Subscription(name: "Cancelled", price: 50, billingDate: .now, status: .archived),
        ]
        XCTAssertEqual(Money.totals(items)["USD"], Decimal(string: "13.99")!)
        XCTAssertEqual(Money.totals(items)["EUR"], 12)
        XCTAssertEqual(Money.totals(items, yearly: true)["USD"], Decimal(string: "167.88")!)
    }

    @MainActor func testPersistence() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "entries.json")
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SubscriptionStore(fileURL: url, defaults: defaults)
        var item = Subscription(name: "Real", price: 8, billingDate: .now, reminderDays: nil)
        store.save(item)
        item.price = 9
        store.save(item)
        XCTAssertEqual(
            SubscriptionStore(fileURL: url, defaults: defaults).subscriptions.first?.price, 9)
        store.deleteSubscription(id: item.id)
        XCTAssertTrue(SubscriptionStore(fileURL: url, defaults: defaults).subscriptions.isEmpty)
    }
}

extension SubscriptionTests {
    func testReminderLeadTimeAndDueDay() {
        let now = date(2026, 10, 1)
        let item = Subscription(
            name: "Trial", price: 10, billingDate: date(2026, 10, 4), status: .trial,
            reminderDays: 2)
        let plan = ReminderPlanner.plan(for: [item], now: now, calendar: calendar)
        XCTAssertEqual(plan.count, 2)
        XCTAssertEqual(plan.map { calendar.component(.day, from: $0.fireDate) }, [2, 4])
        XCTAssertTrue(plan.allSatisfy { calendar.component(.hour, from: $0.fireDate) == 9 })
    }

    func testReminderNearDeadlineAndDisabledPlans() {
        let item = Subscription(
            name: "Soon", price: 10, billingDate: date(2026, 10, 2), status: .trial, reminderDays: 7
        )
        let disabled = Subscription(
            name: "Off", price: 10, billingDate: date(2026, 10, 3), reminderDays: nil)
        let ended = Subscription(
            name: "Ended", price: 10, billingDate: date(2026, 9, 1), status: .trial)
        let plan = ReminderPlanner.plan(
            for: [item, disabled, ended], now: date(2026, 10, 1), calendar: calendar)
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan[0].subscription.name, "Soon")
        XCTAssertEqual(calendar.component(.day, from: plan[0].fireDate), 2)
    }

    func testSameDayReminderIsNotDuplicatedAndNearestAreCapped() {
        let now = date(2026, 10, 1)
        let item = Subscription(
            name: "Same day", price: 10, billingDate: date(2026, 10, 2), status: .trial,
            reminderDays: 0)
        XCTAssertEqual(ReminderPlanner.plan(for: [item], now: now, calendar: calendar).count, 1)
        let items = (2...31).map {
            Subscription(name: "Plan \($0)", price: 5, billingDate: date(2026, 10, $0))
        }
        let plan = ReminderPlanner.plan(for: items, now: now, calendar: calendar)
        XCTAssertEqual(plan.count, 60)
        XCTAssertEqual(plan.map(\.fireDate), plan.map(\.fireDate).sorted())
    }

    @MainActor func testDamagedStoragePreservesRecoveryCopy() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "entries.json")
        let original = Data("damaged file".utf8)
        try original.write(to: url)
        let store = SubscriptionStore(fileURL: url)
        XCTAssertNotNil(store.errorMessage)
        store.save(Subscription(name: "New", price: 5, billingDate: .now, reminderDays: nil))
        let files = try FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil)
        let recovery = try XCTUnwrap(
            files.first { $0.lastPathComponent.hasPrefix("subscriptions-recovery") })
        XCTAssertEqual(try Data(contentsOf: recovery), original)
        XCTAssertEqual(SubscriptionStore(fileURL: url).subscriptions.first?.name, "New")
    }
}
