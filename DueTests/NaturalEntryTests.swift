//
//  NaturalEntryTests.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/8/26.
//

import XCTest

@testable import Due

final class NaturalEntryTests: XCTestCase {
    private struct Fixture: Decodable {
        struct Entity: Decodable {
            let field: String
            let text: String
        }
        let text: String
        let ids: [Int]
        let mask: [Int]
        let ranges: [[Int]]
        let entities: [Entity]?
    }

    private func fixtures() throws -> [Fixture] {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "EntryTokenizerFixtures", withExtension: "json")
        )
        return try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
    }

    func testTokenizerMatchesTrainingTokenizerIncludingUnicode() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "EntryVocabulary", withExtension: "txt"))
        let tokenizer = EntryTokenizer(vocabulary: try String(contentsOf: url, encoding: .utf8))
        for fixture in try fixtures() {
            let actual = try tokenizer.encode(fixture.text)
            XCTAssertEqual(actual.tokens.map(\.id), fixture.ids, fixture.text)
            XCTAssertEqual(actual.mask, fixture.mask, fixture.text)
            XCTAssertEqual(
                actual.tokens.map { [$0.range.location, $0.range.length] }, fixture.ranges,
                fixture.text)
        }
        XCTAssertThrowsError(try tokenizer.encode(String(repeating: "subscription ", count: 128)))
    }

    func testBundledModelMatchesPythonEntityPredictions() async throws {
        for fixture in try fixtures() {
            guard let expected = fixture.entities else { continue }
            let actual = try await SubscriptionEntryInterpreter.shared.extract(fixture.text)
            XCTAssertEqual(
                actual.map { $0.field + ":" + $0.text }, expected.map { $0.field + ":" + $0.text },
                fixture.text)
        }
    }

    func testDraftUsesRecognizedValuesAndPresetWithoutSaving() throws {
        let suggestion = try EntryDraftBuilder().suggestion(
            from: entities([
                ("SERVICE", "Netflix"), ("AMOUNT", "15.99"), ("CURRENCY", "USD"),
                ("CYCLE", "per month"), ("BILLING_DATE", "2026-10-25"),
                ("REMINDER", "two days before"),
            ]), now: today, calendar: calendar)
        XCTAssertTrue(suggestion.unresolved.isEmpty)
        XCTAssertEqual(suggestion.draft.name, "Netflix")
        XCTAssertEqual(suggestion.draft.amount, "15.99")
        XCTAssertEqual(suggestion.draft.currency, "USD")
        XCTAssertEqual(suggestion.draft.cycle, .monthly)
        XCTAssertEqual(suggestion.draft.reminderDays, 2)
        XCTAssertEqual(suggestion.draft.category, .entertainment)
        XCTAssertEqual(suggestion.draft.date, date(2026, 10, 25))
    }

    func testMissingAmbiguousAndUnsupportedValuesRequireChoices() throws {
        let result = try EntryDraftBuilder().suggestion(
            from: entities([
                ("SERVICE", "My plan"), ("AMOUNT", "9.99"), ("CURRENCY", "$"),
                ("CYCLE", "weekly"), ("BILLING_DATE", "10/12/26"), ("REMINDER", "five days before"),
            ]), now: today, calendar: calendar)
        XCTAssertEqual(result.unresolved, [.currency, .cycle, .date, .reminder])
        XCTAssertEqual(result.draft.currency, "")
        XCTAssertEqual(result.draft.reminderDays, -1)
        let missing = try EntryDraftBuilder().suggestion(
            from: entities([("SERVICE", "New service")]), now: today, calendar: calendar)
        XCTAssertEqual(missing.unresolved, [.currency, .cycle, .date])
        XCTAssertEqual(missing.draft.amount, "")
        XCTAssertThrowsError(try missing.draft.subscription(now: today))
    }

    func testTrialDateAndConflictingValues() throws {
        let trial = try EntryDraftBuilder().suggestion(
            from: entities([
                ("SERVICE", "Notion"), ("PLAN_TYPE", "free trial"), ("TRIAL_END", "tomorrow"),
                ("AMOUNT", "8"), ("CURRENCY", "EUR"), ("CYCLE", "monthly"),
            ]), now: today, calendar: calendar)
        XCTAssertEqual(trial.draft.status, .trial)
        XCTAssertEqual(trial.draft.date, date(2026, 10, 9))
        XCTAssertEqual(trial.draft.reminderDays, -1)
        XCTAssertTrue(trial.unresolved.isEmpty)
        let conflict = try EntryDraftBuilder().suggestion(
            from: entities([
                ("SERVICE", "Netflix"), ("AMOUNT", "9"), ("AMOUNT", "12"),
                ("CURRENCY", "USD"), ("CURRENCY", "EUR"), ("CYCLE", "monthly"),
            ]), now: today, calendar: calendar)
        XCTAssertEqual(conflict.draft.amount, "")
        XCTAssertTrue(conflict.unresolved.contains(.currency))
        XCTAssertThrowsError(
            try EntryDraftBuilder().suggestion(from: entities([("PLAN_TYPE", "trial")])))
        XCTAssertThrowsError(
            try EntryDraftBuilder().suggestion(
                from: entities([("SERVICE", "Netflix"), ("SERVICE", "Spotify")])))
    }

    func testDatesUseCalendarAndRejectAmbiguousOrInvalidInput() {
        let parser = EntryDateParser()
        let accepted: [(String, Date)] = [
            ("today", today), ("this Thursday", today), ("next Thursday", date(2026, 10, 15)),
            ("tomorrow", date(2026, 10, 9)),
            ("next Friday", date(2026, 10, 9)), ("in two weeks", date(2026, 10, 22)),
            ("the 5th", date(2026, 11, 5)), ("October 25", date(2026, 10, 25)),
            ("Sep 2", date(2027, 9, 2)), ("2028-02-29", date(2028, 2, 29)),
        ]
        for (phrase, expected) in accepted {
            XCTAssertEqual(
                parser.date(from: phrase, now: today, calendar: calendar), expected, phrase)
        }
        for phrase in [
            "10/12/26", "2026-02-30", "February 30, 2026", "next month", "32nd",
            "October 25 garbage",
        ] {
            XCTAssertNil(parser.date(from: phrase, now: today, calendar: calendar), phrase)
        }
    }

    private func entities(_ values: [(String, String)]) -> [EntryEntity] {
        values.map { EntryEntity(field: $0.0, text: $0.1, confidence: 0.99) }
    }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private var today: Date { date(2026, 10, 8) }
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
