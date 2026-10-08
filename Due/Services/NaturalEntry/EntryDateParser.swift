//
//  EntryDateParser.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/8/26.
//

import Foundation

struct EntryDateParser {
    func date(from phrase: String, now: Date, calendar: Calendar) -> Date? {
        let value = phrase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let today = calendar.startOfDay(for: now)
        if value == "today" { return today }
        if value == "tomorrow" { return calendar.date(byAdding: .day, value: 1, to: today) }
        if value == "in two weeks" { return calendar.date(byAdding: .day, value: 14, to: today) }
        let weekdays = [
            "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday",
        ]
        if let day = weekdays.firstIndex(where: { value == "next \($0)" || value == "this \($0)" })
        {
            let distance = (day + 1 - calendar.component(.weekday, from: today) + 7) % 7
            return calendar.date(
                byAdding: .day, value: distance == 0 && value.hasPrefix("next ") ? 7 : distance,
                to: today)
        }
        if let parts = captures("^(\\d{4})-(\\d{1,2})-(\\d{1,2})$", value),
            let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        {
            return checkedDate(year: year, month: month, day: day, calendar: calendar)
        }
        // Slash dates are deliberately left for the person to resolve.
        if value.contains("/") { return nil }
        if let parts = captures("^(?:on )?(?:the )?(\\d{1,2})(?:st|nd|rd|th)$", value),
            let day = Int(parts[0])
        {
            let year = calendar.component(.year, from: today)
            let month = calendar.component(.month, from: today)
            if let candidate = checkedDate(year: year, month: month, day: day, calendar: calendar),
                candidate >= today
            {
                return candidate
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: today) else {
                return nil
            }
            return checkedDate(
                year: calendar.component(.year, from: next),
                month: calendar.component(.month, from: next), day: day, calendar: calendar)
        }
        let formats = [
            "MMMM d, yyyy", "MMM d, yyyy", "MMMM d yyyy", "MMM d yyyy", "d MMMM yyyy", "d MMM yyyy",
        ]
        for format in formats {
            if let date = formatted(value, format: format, calendar: calendar) { return date }
        }
        for format in ["MMMM d", "MMM d", "d MMMM", "d MMM"] {
            let year = calendar.component(.year, from: today)
            if let date = formatted(
                "\(value) \(year)", format: format + " yyyy", calendar: calendar)
            {
                if date >= today { return date }
                return formatted(
                    "\(value) \(year + 1)", format: format + " yyyy", calendar: calendar)
            }
        }
        return nil
    }

    private func formatted(_ value: String, format: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        formatter.isLenient = false
        return formatter.date(from: value).map(calendar.startOfDay(for:))
    }

    private func checkedDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        guard (1...12).contains(month), (1...31).contains(day),
            let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
            calendar.component(.year, from: date) == year,
            calendar.component(.month, from: date) == month,
            calendar.component(.day, from: date) == day
        else { return nil }
        return date
    }

    private func captures(_ pattern: String, _ text: String) -> [String]? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
            let match = expression.firstMatch(
                in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        return (1..<match.numberOfRanges).map {
            (text as NSString).substring(with: match.range(at: $0))
        }
    }
}
