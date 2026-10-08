//
//  DueUITests.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import XCTest

final class DueUITests: XCTestCase {
    func testAddEditSearchAndDelete() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["addSubscription"].waitForExistence(timeout: 10))
        capture(app, "Empty overview")
        app.buttons["addSubscription"].tap()
        app.buttons["addManually"].tap()
        let name = app.textFields["serviceName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        capture(app, "Add subscription")
        name.tap()
        name.typeText("Test service")
        let price = app.textFields["price"]
        price.tap()
        price.typeText("12.50")
        app.buttons["saveSubscription"].tap()
        app.tabBars.buttons["Subscriptions"].tap()
        let row = app.buttons["subscription-Test service"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.buttons["editSubscription"].tap()
        let edit = app.textFields["serviceName"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        edit.typeText(
            String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Test service".count)
                + "Updated service")
        app.buttons["saveSubscription"].tap()
        app.buttons["Done"].firstMatch.tap()
        let search = app.textFields["subscriptionSearch"]
        search.tap()
        search.typeText("Updated")
        let updated = app.buttons["subscription-Updated service"]
        XCTAssertTrue(updated.waitForExistence(timeout: 5))
        updated.tap()
        app.swipeUp()
        app.buttons["Delete subscription"].tap()
        app.buttons["Delete subscription"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No matching subscriptions"].waitForExistence(timeout: 5))
    }

    func testTrialReviewAndCalendarNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Your month, in view."].waitForExistence(timeout: 10))
        app.buttons["addSubscription"].tap()
        let name = app.textFields["serviceName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Trial service")
        let price = app.textFields["price"]
        price.tap()
        price.typeText("5.99")
        app.buttons["planType"].tap()
        app.buttons["Free trial"].tap()
        app.buttons["saveSubscription"].tap()
        XCTAssertTrue(app.staticTexts["Needs your attention"].waitForExistence(timeout: 5))
        capture(app, "Overview")
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Review trial'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["keepTrial"].waitForExistence(timeout: 5))
        capture(app, "Trial details")
        app.buttons["keepTrial"].tap()
        XCTAssertFalse(app.buttons["keepTrial"].exists)
        app.buttons["Done"].tap()
        app.tabBars.buttons["Subscriptions"].tap()
        capture(app, "Subscriptions")
        app.tabBars.buttons["Calendar"].tap()
        capture(app, "Calendar")
        let original = app.staticTexts[Date.now.formatted(.dateTime.month(.wide).year())].firstMatch
        XCTAssertTrue(original.exists)
        app.buttons["Next month"].tap()
        app.buttons["Previous month"].tap()
        XCTAssertTrue(original.exists)
        app.tabBars.buttons["Settings"].tap()
        capture(app, "Settings")
    }

    func testValidationIsVisible() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["addSubscription"].waitForExistence(timeout: 10))
        app.buttons["addSubscription"].tap()
        app.buttons["saveSubscription"].tap()
        XCTAssertTrue(app.alerts["Check the details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.staticTexts["Enter a service name."].exists)
        app.alerts.buttons["OK"].tap()
        let name = app.textFields["serviceName"]
        name.tap()
        name.typeText("Trial service")
        app.buttons["saveSubscription"].tap()
        XCTAssertTrue(app.alerts["Check the details"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.alerts.staticTexts[
                "Enter a price from 0 to 1,000,000 with up to two decimal places."
            ].exists)
    }

    func testDarkAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Your month, in view."].waitForExistence(timeout: 10))
        capture(app, "Dark overview")
        app.tabBars.buttons["Calendar"].tap()
        capture(app, "Dark calendar")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertFalse(app.staticTexts["Appearance"].exists)
        XCTAssertFalse(app.staticTexts["Display"].exists)
        XCTAssertFalse(app.buttons["Preview with sample data"].exists)
        capture(app, "Dark settings")
    }

    func testServiceBrowserSelection() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["addSubscription"].waitForExistence(timeout: 10))
        app.buttons["addSubscription"].tap()
        capture(app, "Service entry")
        app.buttons["browseServices"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        capture(app, "Browse services")
        search.typeText("Netflix")
        let netflix = app.buttons["servicePreset-Netflix"]
        XCTAssertTrue(netflix.waitForExistence(timeout: 5))
        netflix.tap()
        XCTAssertEqual(app.textFields["serviceName"].value as? String, "Netflix")
        XCTAssertFalse(app.buttons["servicePreset-Netflix"].exists)
    }

    func testDescriptionFillsDraftAndSavesAfterReview() {
        let app = descriptionEntry(
            "Could you record Netflix? USD 15.49 comes out monthly and the upcoming bill is November 14."
        )
        XCTAssertTrue(app.switches["confirmEntryDetails"].waitForExistence(timeout: 30))
        XCTAssertEqual(app.textFields["serviceName"].value as? String, "Netflix")
        XCTAssertEqual(app.textFields["price"].value as? String, "15.49")
        XCTAssertFalse(app.buttons["saveSubscription"].isEnabled)
        capture(app, "Recognized subscription draft")
        app.switches["confirmEntryDetails"].switches.firstMatch.tap()
        XCTAssertTrue(app.buttons["saveSubscription"].isEnabled)
        app.buttons["saveSubscription"].tap()
        app.tabBars.buttons["Subscriptions"].tap()
        XCTAssertTrue(app.buttons["subscription-Netflix"].waitForExistence(timeout: 5))
        app.buttons["subscription-Netflix"].tap()
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS '15.49'")).firstMatch
                .exists)
        capture(app, "Saved description entry")
    }

    func testAmbiguousDescriptionRequiresCurrencyAndDate() {
        let app = descriptionEntry("Audible costs $14.95 monthly; billing 11/12/2026.")
        XCTAssertTrue(app.switches["confirmEntryDetails"].waitForExistence(timeout: 30))
        app.switches["confirmEntryDetails"].switches.firstMatch.tap()
        XCTAssertFalse(app.buttons["saveSubscription"].isEnabled)
        app.swipeUp()
        app.buttons["entryCurrency"].tap()
        app.buttons["USD"].tap()
        XCTAssertFalse(app.buttons["saveSubscription"].isEnabled)
        app.buttons["confirmEntryDate"].tap()
        XCTAssertTrue(app.buttons["saveSubscription"].isEnabled)
        capture(app, "Resolved description choices")
        app.buttons["saveSubscription"].tap()
        app.tabBars.buttons["Subscriptions"].tap()
        XCTAssertTrue(app.buttons["subscription-Audible"].waitForExistence(timeout: 5))
    }

    func testDescriptionTrialCanBeReviewedAndCancelled() {
        let app = descriptionEntry(
            "Make an entry for Headspace while I am on the trial; the last day is October 20, afterwards 12.99 USD monthly."
        )
        XCTAssertTrue(app.switches["confirmEntryDetails"].waitForExistence(timeout: 30))
        XCTAssertEqual(app.textFields["serviceName"].value as? String, "Headspace")
        XCTAssertTrue(app.buttons["planType"].label.contains("Free trial"))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Trial ends"].exists)
        capture(app, "Recognized trial draft")
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Subscriptions"].tap()
        XCTAssertFalse(app.buttons["subscription-Headspace"].exists)
    }

    func testDescriptionFailureKeepsTextAndOffersManualEntry() {
        let text = "Please tell me the weather tomorrow."
        let app = descriptionEntry(text)
        XCTAssertTrue(app.buttons["entryManualFallback"].waitForExistence(timeout: 30))
        XCTAssertEqual(
            app.descendants(matching: .any)["subscriptionDescription"].firstMatch.value as? String,
            text)
        capture(app, "Description entry fallback")
        app.buttons["entryManualFallback"].tap()
        XCTAssertTrue(app.textFields["serviceName"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["saveSubscription"].isEnabled)
    }

    private func descriptionEntry(_ text: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["addSubscription"].waitForExistence(timeout: 10))
        app.buttons["addSubscription"].tap()
        app.buttons["describeSubscription"].tap()
        let input = app.descendants(matching: .any)["subscriptionDescription"].firstMatch
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText(text)
        app.buttons["Done"].firstMatch.tap()
        capture(app, "Description entry")
        app.buttons["interpretSubscription"].tap()
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
