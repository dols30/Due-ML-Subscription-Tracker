//
//  SubscriptionExporter.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation

enum SubscriptionExporter {
    static func csv(for subscriptions: [Subscription]) -> String {
        func cell(_ value: String) -> String {
            // Prevent spreadsheet formula execution when opening user-entered names or notes.
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let safe =
                ["=", "+", "-", "@"].contains(where: { normalized.hasPrefix($0) })
                ? "'" + value : value
            return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var rows = [
            "Name,Price,Currency,Cycle,Billing date,Status,Category,Reminder days,Management link,Notes"
        ]
        for item in subscriptions {
            let values = [
                item.name, NSDecimalNumber(decimal: item.price).stringValue, item.currency,
                item.cycle.rawValue, dateFormatter.string(from: item.billingDate),
                item.status.rawValue, item.category.rawValue,
                item.reminderDays.map(String.init) ?? "off", item.managementURL, item.notes,
            ]
            rows.append(values.map(cell).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func export(_ subscriptions: [Subscription]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "Due-subscriptions.csv")
        try csv(for: subscriptions).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
