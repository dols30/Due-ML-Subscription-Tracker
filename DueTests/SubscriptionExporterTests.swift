//
//  SubscriptionExporterTests.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import XCTest

@testable import Due

final class SubscriptionExporterTests: XCTestCase {
    func testExportEscapesQuotesCommasAndFormulaPrefixes() {
        let subscription = Subscription(
            name: "=SUM(1,2)", price: Decimal(string: "12.50")!, billingDate: .now,
            reminderDays: nil, notes: "Shared \"family\" plan, two people"
        )
        let csv = SubscriptionExporter.csv(for: [subscription])
        XCTAssertTrue(csv.contains("\"'=SUM(1,2)\""))
        XCTAssertTrue(csv.contains("\"Shared \"\"family\"\" plan, two people\""))
        XCTAssertTrue(csv.contains("\"off\""))
        XCTAssertTrue(csv.contains("\"12.5\""))
    }
}
