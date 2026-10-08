//
//  EntryDraftBuilder.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/8/26.
//

import Foundation

enum EntryReviewField: Hashable {
    case currency, cycle, date, reminder, planType
}

struct EntrySuggestion {
    var draft: SubscriptionDraft
    var unresolved: Set<EntryReviewField>
}

struct EntryDraftBuilder {
    func suggestion(
        from entities: [EntryEntity], now: Date = .now,
        calendar: Calendar = .current
    ) throws -> EntrySuggestion {
        let grouped = Dictionary(grouping: entities.filter { $0.confidence >= 0.8 }, by: \.field)
        func value(_ field: String) -> String? {
            let values = Set(
                (grouped[field] ?? []).map {
                    $0.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                })
            guard values.count == 1 else { return nil }
            return grouped[field]?.first?.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let name = value("SERVICE"), !name.isEmpty else { throw EntryError.noDetails }
        var draft = SubscriptionDraft()
        var unresolved: Set<EntryReviewField> = []
        draft.name = name
        draft.category = .other
        draft.reminderDays = -1
        draft.date = calendar.startOfDay(for: now)
        if let preset = ServicePreset.all.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            draft.name = preset.name
            draft.category = preset.category
            draft.managementURL = preset.managementURL
        }
        if let amount = value("AMOUNT"),
            amount.range(of: "^[0-9]+([.,][0-9]{1,2})?$", options: .regularExpression) != nil
        {
            draft.amount = amount.replacingOccurrences(of: ",", with: ".")
        }
        draft.currency = value("CURRENCY").flatMap(currency) ?? ""
        if draft.currency.isEmpty { unresolved.insert(.currency) }
        if let cycle = value("CYCLE").flatMap(billingCycle) {
            draft.cycle = cycle
        } else {
            unresolved.insert(.cycle)
        }
        let plan = value("PLAN_TYPE")?.lowercased()
        if plan?.contains("trial") == true || grouped["TRIAL_END"] != nil {
            draft.status = .trial
        }
        if (grouped["PLAN_TYPE"] != nil && plan == nil)
            || (grouped["TRIAL_END"] != nil && plan?.contains("paid") == true)
        {
            unresolved.insert(.planType)
        }
        let dateField = draft.status == .trial ? "TRIAL_END" : "BILLING_DATE"
        if let phrase = value(dateField),
            let date = EntryDateParser().date(from: phrase, now: now, calendar: calendar)
        {
            draft.date = date
        } else {
            unresolved.insert(.date)
        }
        if grouped["BILLING_DATE"] != nil && grouped["TRIAL_END"] != nil {
            unresolved.formUnion([.date, .planType])
        }
        if grouped["REMINDER"] != nil {
            if let days = value("REMINDER").flatMap(reminderDays) {
                draft.reminderDays = days
            } else {
                unresolved.insert(.reminder)
            }
        }
        return EntrySuggestion(draft: draft, unresolved: unresolved)
    }

    private func currency(_ phrase: String) -> String? {
        let value = phrase.lowercased()
        if Money.currencies.contains(phrase.uppercased()) { return phrase.uppercased() }
        let aliases = [
            "us dollars": "USD", "us dollar": "USD", "u.s. dollars": "USD", "us$": "USD",
            "€": "EUR", "euros": "EUR", "euro": "EUR",
            "£": "GBP", "british pounds": "GBP", "pounds sterling": "GBP",
            "canadian dollars": "CAD", "ca$": "CAD", "c$": "CAD",
            "australian dollars": "AUD", "a$": "AUD",
            "indian rupees": "INR", "₹": "INR",
            "nepali rupees": "NPR", "nepalese rupees": "NPR",
            "japanese yen": "JPY", "yen": "JPY",
        ]
        // A bare dollar sign or "dollars" doesn't identify a currency.
        return aliases[value]
    }

    private func billingCycle(_ phrase: String) -> BillingCycle? {
        switch phrase.lowercased() {
        case "monthly", "per month", "a month", "each month", "every month", "/month", "/mo":
            .monthly
        case "yearly", "annually", "annual", "per year", "a year", "each year", "every year",
            "/year", "/yr":
            .yearly
        default: nil
        }
    }

    private func reminderDays(_ phrase: String) -> Int? {
        let value = phrase.lowercased()
        if ["off", "no reminder", "no reminders", "without reminders"].contains(value) {
            return -1
        }
        if ["on the day", "same day", "on the billing date", "on the charge date"].contains(value) {
            return 0
        }
        let words = ["one": 1, "two": 2, "three": 3, "seven": 7]
        for (word, days) in words {
            if value == "\(word) day\(days == 1 ? "" : "s") before"
                || value == "\(days) day\(days == 1 ? "" : "s") before"
            {
                return days
            }
        }
        if value == "a day before" || value == "the day before" { return 1 }
        if value == "a week before" || value == "one week before" || value == "1 week before" {
            return 7
        }
        return nil
    }
}
