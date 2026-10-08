//
//  SpendingSummaryCard.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct SpendingSummaryCard: View {
    @Environment(SubscriptionStore.self) private var store
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize = 46
    @State private var yearly = false
    @State private var selectedCurrency = "USD"
    private var totals: [String: Decimal] { Money.totals(store.subscriptions, yearly: yearly) }
    private var currency: String {
        totals[selectedCurrency] != nil ? selectedCurrency : totals.keys.sorted().first ?? "USD"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Subscription spending").font(.subheadline).foregroundStyle(
                    .white.opacity(0.75))
                Spacer()
                Menu {
                    Button("Monthly") { yearly = false }
                    Button("Yearly") { yearly = true }
                    if totals.count > 1 {
                        Divider()
                        ForEach(totals.keys.sorted(), id: \.self) { code in
                            Button(code) { selectedCurrency = code }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(yearly ? "Yearly" : "Monthly")
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .font(.caption.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.white.opacity(0.1), in: Capsule())
                }.accessibilityLabel("Spending period")
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(Money.format(totals[currency] ?? 0, currency: currency)).font(
                    .system(size: amountSize, weight: .medium)
                ).minimumScaleFactor(0.5).lineLimit(1)
                Text(
                    yearly ? "Yearly equivalent · \(currency)" : "Monthly equivalent · \(currency)"
                ).font(.caption).foregroundStyle(.white.opacity(0.6))
                if totals.count > 1 {
                    Text("Currencies are shown separately").font(.caption).foregroundStyle(
                        .white.opacity(0.7))
                }
            }
            Rectangle().fill(.white.opacity(0.13)).frame(height: 1)
            HStack {
                Label(
                    "\(store.currentSubscriptions.filter { $0.status == .active }.count) active plans",
                    systemImage: "square.stack"
                ).font(.subheadline)
                Spacer()
                Label("\(store.trialSubscriptions.count) free trials", systemImage: "hourglass")
                    .font(.subheadline).foregroundStyle(Color(red: 0.72, green: 0.8, blue: 0.96))
            }
        }.foregroundStyle(.white).padding(24)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.19, blue: 0.25),
                        Color(red: 0.09, green: 0.11, blue: 0.16),
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 28))
    }

}
