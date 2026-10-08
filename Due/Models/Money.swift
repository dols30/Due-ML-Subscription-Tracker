//
//  Money.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation

struct Money {
    static let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "NPR", "JPY"]
    static func format(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }

    static func totals(_ items: [Subscription], yearly: Bool = false) -> [String: Decimal] {
        items.filter { $0.status == .active }.reduce(into: [:]) { result, item in
            result[item.currency, default: 0] += item.monthlyPrice * (yearly ? 12 : 1)
        }
    }
}
