//
//  ReminderPlanner.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation

struct PlannedReminder {
    let fireDate: Date
    let subscription: Subscription
    let chargeDate: Date
}

enum ReminderPlanner {
    static func plan(
        for subscriptions: [Subscription], now: Date = .now, calendar: Calendar = .current,
        limit: Int = 60
    ) -> [PlannedReminder] {
        guard let horizon = calendar.date(byAdding: .year, value: 1, to: now) else { return [] }
        var reminders: [PlannedReminder] = []
        for item in subscriptions where item.status != .archived {
            guard let days = item.reminderDays else { continue }
            for date in item.events(
                in: DateInterval(start: calendar.startOfDay(for: now), end: horizon),
                calendar: calendar)
            {
                for offset in Set([days, 0]) {
                    guard let day = calendar.date(byAdding: .day, value: -offset, to: date),
                        let fire = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day),
                        fire > now
                    else { continue }
                    reminders.append(
                        PlannedReminder(fireDate: fire, subscription: item, chargeDate: date))
                }
            }
        }
        return Array(reminders.sorted { $0.fireDate < $1.fireDate }.prefix(max(0, limit)))
    }
}
