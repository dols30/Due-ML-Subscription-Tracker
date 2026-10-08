//
//  OverviewView.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct OverviewView: View {
    @Environment(SubscriptionStore.self) private var store
    var add: () -> Void
    var select: (Subscription) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.hexagongrid.fill").font(.title3).foregroundStyle(
                            DueTheme.accent)
                        Text("Due").font(.system(.title2, weight: .bold))
                    }
                    Spacer()
                    Button(action: add) {
                        Image(systemName: "plus").font(.system(size: 19, weight: .medium)).frame(
                            width: 44, height: 44
                        ).background(DueTheme.surface, in: Circle())
                    }
                    .accessibilityLabel("Add subscription").accessibilityIdentifier(
                        "addSubscription")
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(Date.now.formatted(.dateTime.month(.wide).year())).font(.subheadline)
                        .foregroundStyle(DueTheme.secondary)
                    Text("Your month, in view.").font(
                        .system(.largeTitle, weight: .bold)
                    )
                }
                if store.currentSubscriptions.isEmpty {
                    welcome
                } else {
                    SpendingSummaryCard()
                    attention
                    upcoming

                }
            }.padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 24).frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
        }.background(DueTheme.canvas).toolbar(.hidden, for: .navigationBar)
    }

    private var welcome: some View {
        Surface {
            EmptyState(
                symbol: "calendar.badge.clock", title: "Before the next charge",
                message:
                    "Keep your subscriptions in one place, with a reminder before a trial ends or a plan renews."
            )
            Button("Add your first subscription", action: add).buttonStyle(PrimaryButton())
        }
    }

    @ViewBuilder private var attention: some View {
        if let trial = store.trialSubscriptions.first {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading(
                    title: "Needs your attention",
                    detail:
                        "\(store.trialSubscriptions.count) \(store.trialSubscriptions.count == 1 ? "trial" : "trials")"
                )
                Button {
                    select(trial)
                } label: {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 13) {
                            ServiceIcon(item: trial, size: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trial.name).font(.system(.body, weight: .semibold))
                                    .foregroundStyle(DueTheme.ink)
                                Text(deadline(trial)).font(.subheadline).foregroundStyle(
                                    DueTheme.accent)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.body).foregroundStyle(
                                DueTheme.accent)
                        }
                        HStack(alignment: .center) {
                            Text(
                                "Then \(Money.format(trial.price, currency: trial.currency))\(trial.cycle.suffix)"
                            ).font(.subheadline).foregroundStyle(DueTheme.secondary)
                            Spacer()
                            Text("Review trial").font(.subheadline.weight(.semibold))
                                .foregroundStyle(DueTheme.accent)
                        }
                    }.padding(19).background(
                        DueTheme.softBlue, in: RoundedRectangle(cornerRadius: 22))
                }.buttonStyle(.plain)
            }
        }
    }

    private func deadline(_ item: Subscription) -> String {
        let days = item.daysRemaining()
        if days < 0 { return "Trial ended · review now" }
        if days == 0 { return "Trial ends today" }
        return "Trial ends in \(days) \(days == 1 ? "day" : "days")"
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Coming up", detail: "Next charges")
            Surface(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(
                        Array(store.upcomingSubscriptions.prefix(4).enumerated()), id: \.element.id
                    ) { index, item in
                        if index > 0 { Divider().overlay(DueTheme.line).padding(.leading, 62) }
                        Button {
                            select(item)
                        } label: {
                            SubscriptionRow(item: item)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#if DEBUG
    #Preview("Overview") {
        PreviewContainer {
            NavigationStack { OverviewView(add: {}, select: { _ in }) }
        }
    }
#endif
