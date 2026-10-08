//
//  ReminderScheduler.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation
import UserNotifications

@MainActor
final class ReminderScheduler {
    private var scheduleRevision = 0

    func schedule(_ subscriptions: [Subscription], enabled: Bool) async throws {
        scheduleRevision += 1
        let revision = scheduleRevision
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let status = await center.notificationSettings().authorizationStatus
        guard revision == scheduleRevision else { return }
        guard enabled, status == .authorized || status == .provisional else { return }
        let calendar = Calendar.current
        for planned in ReminderPlanner.plan(for: subscriptions) {
            guard revision == scheduleRevision else { return }
            let request = notificationRequest(for: planned, revision: revision, calendar: calendar)
            try await center.add(request)
            if revision != scheduleRevision {
                center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            }
        }
    }

    private func notificationRequest(
        for planned: PlannedReminder, revision: Int, calendar: Calendar
    ) -> UNNotificationRequest {
        let fire = planned.fireDate
        let item = planned.subscription
        let date = planned.chargeDate
        let content = UNMutableNotificationContent()
        let isDueDay = calendar.isDate(fire, inSameDayAs: date)
        content.title =
            item.status == .trial
            ? "\(item.name) trial \(isDueDay ? "ends today" : "is ending")"
            : "\(item.name) \(isDueDay ? "renews today" : "renews soon")"
        content.body =
            "\(Money.format(item.price, currency: item.currency)) on \(date.formatted(date: .abbreviated, time: .omitted)). Review it before you’re charged."
        content.sound = .default
        content.userInfo = ["subscriptionID": item.id.uuidString]
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fire), repeats: false)
        let identifier = "\(revision)-\(item.id)-\(fire.timeIntervalSince1970)"
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
