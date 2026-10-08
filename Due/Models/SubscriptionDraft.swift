//
//  SubscriptionDraft.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation

struct SubscriptionDraft {
    var name: String
    var amount: String
    var currency: String
    var cycle: BillingCycle
    var date: Date
    var status: SubscriptionStatus
    var category: ServiceCategory
    var reminderDays: Int
    var managementURL: String
    var notes: String

    init(subscription: Subscription? = nil) {
        name = subscription?.name ?? ""
        amount = subscription.map { NSDecimalNumber(decimal: $0.price).stringValue } ?? ""
        currency = subscription?.currency ?? "USD"
        cycle = subscription?.cycle ?? .monthly
        date = subscription?.billingDate ?? Calendar.current.startOfDay(for: .now)
        status = subscription?.status ?? .active
        category = subscription?.category ?? .entertainment
        reminderDays = subscription?.reminderDays ?? (subscription == nil ? 2 : -1)
        managementURL = subscription?.managementURL ?? ""
        notes = subscription?.notes ?? ""
    }

    func subscription(
        replacing existing: Subscription? = nil,
        now: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) throws -> Subscription {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw ValidationError.missingName }

        let normalizedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: locale.decimalSeparator ?? ".", with: ".")
        guard
            normalizedAmount.range(of: "^[0-9]+(\\.[0-9]{1,2})?$", options: .regularExpression)
                != nil,
            let price = Decimal(
                string: normalizedAmount, locale: Locale(identifier: "en_US_POSIX")),
            price >= 0, price <= 1_000_000
        else { throw ValidationError.invalidPrice }

        guard Money.currencies.contains(currency) else { throw ValidationError.invalidCurrency }

        if currency == "JPY", price != Decimal(NSDecimalNumber(decimal: price).int64Value) {
            throw ValidationError.fractionalYen
        }

        let link = managementURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !link.isEmpty {
            guard let url = URL(string: link),
                let scheme = url.scheme?.lowercased(),
                ["http", "https"].contains(scheme), url.host != nil
            else { throw ValidationError.invalidLink }
        }

        let isPastTrial =
            status == .trial && calendar.startOfDay(for: date) < calendar.startOfDay(for: now)
        if isPastTrial, existing?.billingDate != date {
            throw ValidationError.pastTrialDate
        }

        var subscription = Subscription(
            name: trimmedName, price: price, currency: currency, cycle: cycle,
            billingDate: date, status: status, category: category,
            reminderDays: reminderDays < 0 ? nil : reminderDays,
            managementURL: link, notes: notes
        )
        if let existing { subscription.id = existing.id }
        return subscription
    }

    enum ValidationError: LocalizedError {
        case missingName, invalidPrice, invalidCurrency, fractionalYen, invalidLink, pastTrialDate

        var errorDescription: String? {
            switch self {
            case .missingName: "Enter a service name."
            case .invalidPrice: "Enter a price from 0 to 1,000,000 with up to two decimal places."
            case .invalidCurrency: "Choose a supported currency."
            case .fractionalYen: "Enter a whole number for a price in JPY."
            case .invalidLink: "Enter a full website link starting with https://."
            case .pastTrialDate: "Choose today or a future trial end date."
            }
        }
    }
}
