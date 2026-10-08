//
//  SharedViews.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct Surface<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(DueTheme.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DueTheme.line, lineWidth: 0.5))
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.body, weight: .semibold))
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .foregroundStyle(.white).background(
                DueTheme.blue, in: RoundedRectangle(cornerRadius: 16)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SectionHeading: View {
    let title: String
    var detail: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(.title3, weight: .semibold))
            Spacer()
            if let detail { Text(detail).font(.subheadline).foregroundStyle(DueTheme.secondary) }
        }
    }
}

struct SubscriptionRow: View {
    let item: Subscription
    var date: Date? = nil
    var body: some View {
        HStack(spacing: 14) {
            ServiceIcon(item: item)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name).font(.system(.body, weight: .semibold)).foregroundStyle(
                    DueTheme.ink)
                Text(
                    item.status == .archived
                        ? "Cancelled"
                        : (item.status == .trial ? "Trial ends " : "Renews ")
                            + (date ?? item.nextCharge()).formatted(
                                .dateTime.month(.abbreviated).day())
                )
                .font(.subheadline).foregroundStyle(DueTheme.secondary)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 5) {
                Text(Money.format(item.price, currency: item.currency)).font(
                    .system(.body, weight: .semibold)
                ).foregroundStyle(DueTheme.ink)
                Text(item.status == .trial ? "Free trial" : item.cycle.title).font(.caption)
                    .foregroundStyle(item.status == .trial ? DueTheme.accent : DueTheme.secondary)
            }
        }.padding(.vertical, 9).contentShape(Rectangle()).accessibilityElement(children: .combine)
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 36, weight: .light)).foregroundStyle(
                DueTheme.accent
            )
            .frame(width: 80, height: 80).background(
                DueTheme.softBlue, in: RoundedRectangle(cornerRadius: 26))
            Text(title).font(.system(.title2, weight: .semibold))
            Text(message).font(.body).foregroundStyle(DueTheme.secondary).multilineTextAlignment(
                .center
            ).lineSpacing(4)
        }.frame(maxWidth: .infinity).padding(.vertical, 28)
    }
}
