//
//  Subscription.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case monthly, yearly
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var suffix: String { self == .monthly ? "/mo" : "/yr" }
    var component: Calendar.Component { self == .monthly ? .month : .year }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case active, trial, archived
}

enum ServiceCategory: String, Codable, CaseIterable, Identifiable {
    case entertainment = "Entertainment"
    case productivity = "Productivity"
    case storage = "Storage"
    case education = "Education"
    case fitness = "Fitness"
    case other = "Other"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .entertainment: "play.rectangle"
        case .productivity: "square.stack.3d.up"
        case .storage: "externaldrive"
        case .education: "book"
        case .fitness: "figure.run"
        case .other: "square.grid.2x2"
        }
    }
}

struct Subscription: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var price: Decimal
    var currency: String = "USD"
    var cycle: BillingCycle = .monthly
    var billingDate: Date
    var status: SubscriptionStatus = .active
    var category: ServiceCategory = .entertainment
    var reminderDays: Int? = 2
    var managementURL: String = ""
    var notes: String = ""

    func nextCharge(after date: Date = .now, calendar: Calendar = .current) -> Date {
        guard status == .active else { return billingDate }
        let today = calendar.startOfDay(for: date)
        let anchor = calendar.startOfDay(for: billingDate)
        guard anchor < today else { return anchor }
        let distance =
            calendar.dateComponents([cycle.component], from: anchor, to: today).value(
                for: cycle.component) ?? 0
        var offset = max(0, distance)
        var next = calendar.date(byAdding: cycle.component, value: offset, to: anchor) ?? anchor
        while next < today {
            offset += 1
            next = calendar.date(byAdding: cycle.component, value: offset, to: anchor) ?? today
        }
        return next
    }

    func daysRemaining(at date: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: nextCharge(after: date, calendar: calendar))
        ).day ?? 0
    }

    func events(in interval: DateInterval, calendar: Calendar = .current) -> [Date] {
        guard status != .archived else { return [] }
        if status == .trial {
            return billingDate >= interval.start && billingDate < interval.end ? [billingDate] : []
        }
        var next = nextCharge(after: interval.start, calendar: calendar)
        var dates: [Date] = []
        while next < interval.end && dates.count < 32 {
            if next >= interval.start { dates.append(next) }
            // Always advance from the original anchor so January 31 does not drift to March 28.
            let components = calendar.dateComponents(
                [cycle.component], from: calendar.startOfDay(for: billingDate), to: next)
            var offset = max(0, components.value(for: cycle.component) ?? 0) + 1
            var candidate =
                calendar.date(byAdding: cycle.component, value: offset, to: billingDate)
                ?? interval.end
            while calendar.startOfDay(for: candidate) <= calendar.startOfDay(for: next) {
                offset += 1
                candidate =
                    calendar.date(byAdding: cycle.component, value: offset, to: billingDate)
                    ?? interval.end
            }
            next = candidate
        }
        return dates
    }

    var monthlyPrice: Decimal { cycle == .monthly ? price : price / 12 }

}
