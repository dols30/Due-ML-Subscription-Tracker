//
//  BillingCalendarView.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct ChargeEvent: Identifiable {
    let item: Subscription
    let date: Date
    var id: String { "\(item.id)-\(date.timeIntervalSince1970)" }
}

struct BillingCalendarView: View {
    @Environment(SubscriptionStore.self) private var store
    var select: (Subscription) -> Void
    @State private var month = Date.now
    @State private var selectedDay: Date?
    private var calendar: Calendar { .current }
    private var interval: DateInterval {
        calendar.dateInterval(of: .month, for: month) ?? DateInterval(start: month, duration: 0)
    }

    private var events: [ChargeEvent] {
        store.currentSubscriptions.flatMap { item in
            item.events(in: interval).map { ChargeEvent(item: item, date: $0) }
        }.sorted { $0.date < $1.date }
    }

    private var visibleEvents: [ChargeEvent] {
        guard let selectedDay else { return events }
        return events.filter { calendar.isDate($0.date, inSameDayAs: selectedDay) }
    }

    private var days: [Date?] {
        let start = interval.start
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        return Array(repeating: nil, count: offset)
            + (0..<count).map { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var weekdays: [String] {
        let names = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { names[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Surface(padding: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            Text(month.formatted(.dateTime.month(.wide).year())).font(
                                .system(.title3, weight: .semibold))
                            Spacer()
                            Button {
                                move(-1)
                            } label: {
                                Image(systemName: "chevron.left").frame(width: 36, height: 44)
                            }.accessibilityLabel("Previous month")
                            Button {
                                move(1)
                            } label: {
                                Image(systemName: "chevron.right").frame(width: 36, height: 44)
                            }.accessibilityLabel("Next month")
                        }
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                            spacing: 5
                        ) {
                            ForEach(Array(weekdays.enumerated()), id: \.offset) { _, value in
                                Text(value).font(.caption.weight(.medium)).foregroundStyle(
                                    DueTheme.secondary
                                ).frame(height: 20).accessibilityHidden(true)
                            }
                            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                                if let date {
                                    dayButton(for: date)
                                } else {
                                    Color.clear.frame(height: 44).accessibilityHidden(true)
                                }
                            }
                        }
                        Divider()
                        HStack {
                            Label("\(events.count) scheduled charges", systemImage: "circle.fill")
                                .font(.caption).foregroundStyle(DueTheme.secondary)
                            Spacer()
                            Button("Today") {
                                month = .now
                                selectedDay = .now
                            }.font(.caption.weight(.semibold)).frame(minHeight: 44)
                        }
                    }
                }
                HStack {
                    SectionHeading(
                        title: selectedDay?.formatted(.dateTime.month(.wide).day()) ?? "This month",
                        detail: selectedDay == nil ? "Billing schedule" : nil)
                    if selectedDay != nil {
                        Button("All dates") { selectedDay = nil }.font(.subheadline).frame(
                            minHeight: 44)
                    }
                }
                if visibleEvents.isEmpty {
                    EmptyState(
                        symbol: "calendar", title: "No charges scheduled",
                        message: selectedDay == nil
                            ? "Your plans for this month will appear here."
                            : "Nothing is due on this day.")
                } else {
                    VStack(spacing: 14) {
                        ForEach(visibleEvents) { event in
                            HStack(alignment: .center, spacing: 14) {
                                VStack(spacing: 4) {
                                    Text(event.date.formatted(.dateTime.weekday(.abbreviated)))
                                        .font(.caption).foregroundStyle(DueTheme.secondary)
                                    Text(event.date.formatted(.dateTime.day())).font(
                                        .system(.title2, weight: .semibold))
                                }.frame(width: 38)
                                Button {
                                    select(event.item)
                                } label: {
                                    Surface(padding: 14) {
                                        SubscriptionRow(item: event.item, date: event.date)
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
            }.padding(24).frame(maxWidth: 640).frame(maxWidth: .infinity)
        }.background(DueTheme.canvas).navigationTitle("Calendar")
    }

    private func dayButton(for date: Date) -> some View {
        let chosen = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let hasCharge = events.contains { calendar.isDate($0.date, inSameDayAs: date) }
        return Button {
            selectedDay = chosen ? nil : date
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))").font(
                    .system(
                        .body,
                        weight: calendar.isDateInToday(date) ? .bold : .regular)
                ).lineLimit(1).minimumScaleFactor(0.6)
                Circle().fill(hasCharge ? (chosen ? Color.white : DueTheme.accent) : .clear).frame(
                    width: 4, height: 4)
            }.frame(maxWidth: .infinity).frame(height: 44)
                .foregroundStyle(chosen ? .white : DueTheme.ink)
                .background(
                    chosen
                        ? DueTheme.blue : calendar.isDateInToday(date) ? DueTheme.softBlue : .clear,
                    in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
            .accessibilityLabel(
                date.formatted(.dateTime.month(.wide).day())
                    + (hasCharge ? ", charge scheduled" : ", no charges")
            )
            .accessibilityAddTraits(chosen ? .isSelected : [])

    }

    private func move(_ value: Int) {
        month = calendar.date(byAdding: .month, value: value, to: interval.start) ?? month
        selectedDay = nil
    }
}

#if DEBUG
    #Preview("Calendar") {
        PreviewContainer {
            NavigationStack { BillingCalendarView(select: { _ in }) }
        }
    }
#endif
