//
//  SubscriptionDraftTests.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import XCTest

@testable import Due

final class SubscriptionDraftTests: XCTestCase {
    private let locale = Locale(identifier: "en_US_POSIX")

    func testLocalizedPriceAndEditingPreserveIdentity() throws {
        let existing = Subscription(name: "Old", price: 8, billingDate: .now)
        var draft = SubscriptionDraft(subscription: existing)
        draft.name = "  Updated  "
        draft.amount = "12,50"
        let result = try draft.subscription(
            replacing: existing, locale: Locale(identifier: "de_DE"))
        XCTAssertEqual(result.id, existing.id)
        XCTAssertEqual(result.name, "Updated")
        XCTAssertEqual(result.price, Decimal(string: "12.50"))
    }

    func testRejectsMissingNameAndInvalidPrices() {
        var draft = SubscriptionDraft()
        draft.amount = "10"
        XCTAssertThrowsError(try draft.subscription(locale: locale)) { error in
            XCTAssertEqual(error as? SubscriptionDraft.ValidationError, .missingName)
        }
        draft.name = "Plan"
        for amount in ["", "-1", "1.234", "1000001", "1e3"] {
            draft.amount = amount
            XCTAssertThrowsError(try draft.subscription(locale: locale)) { error in
                XCTAssertEqual(error as? SubscriptionDraft.ValidationError, .invalidPrice)
            }
        }
    }

    func testRejectsFractionalYenAndNonWebsiteLinks() {
        var draft = SubscriptionDraft()
        draft.name = "Plan"
        draft.amount = "12.50"
        draft.currency = "JPY"
        XCTAssertThrowsError(try draft.subscription(locale: locale)) { error in
            XCTAssertEqual(error as? SubscriptionDraft.ValidationError, .fractionalYen)
        }
        draft.currency = "USD"
        draft.managementURL = "javascript:alert(1)"
        XCTAssertThrowsError(try draft.subscription(locale: locale)) { error in
            XCTAssertEqual(error as? SubscriptionDraft.ValidationError, .invalidLink)
        }
    }

    func testRejectsUnresolvedCurrency() {
        var draft = SubscriptionDraft()
        draft.name = "Plan"
        draft.amount = "9.99"
        for currency in ["", "$", "XYZ"] {
            draft.currency = currency
            XCTAssertThrowsError(try draft.subscription(locale: locale)) { error in
                XCTAssertEqual(error as? SubscriptionDraft.ValidationError, .invalidCurrency)
            }
        }
    }

    func testExpiredTrialCanBeEditedButNotCreated() throws {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let existing = Subscription(name: "Trial", price: 5, billingDate: yesterday, status: .trial)
        var draft = SubscriptionDraft(subscription: existing)
        draft.notes = "Needs review"
        XCTAssertNoThrow(try draft.subscription(replacing: existing, now: now, locale: locale))
        XCTAssertThrowsError(try draft.subscription(now: now, locale: locale)) { error in
            XCTAssertEqual(error as? SubscriptionDraft.ValidationError, .pastTrialDate)
        }
    }
}
