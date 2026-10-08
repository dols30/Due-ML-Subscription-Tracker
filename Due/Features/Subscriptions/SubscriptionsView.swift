//
//  SubscriptionsView.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct SubscriptionsView: View {
    @Environment(SubscriptionStore.self) private var store
    var add: () -> Void
    var select: (Subscription) -> Void
    @State private var search = ""
    @State private var filter = SubscriptionFilter.all
    @State private var alphabetical = false
    private var items: [Subscription] {
        store.subscriptions.filter { item in
            let matches = filter.includes(item)
            return matches
                && (search.isEmpty || item.name.localizedCaseInsensitiveContains(search)
                    || item.category.rawValue.localizedCaseInsensitiveContains(search))
        }.sorted {
            alphabetical
                ? $0.name.localizedStandardCompare($1.name) == .orderedAscending
                : $0.nextCharge() < $1.nextCharge()
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("\(store.currentSubscriptions.count) plans, one place.").font(.subheadline)
                        .foregroundStyle(DueTheme.secondary)
                    Spacer()
                    Menu {
                        Button("Next charge", systemImage: "calendar") { alphabetical = false }
                        Button("Name", systemImage: "textformat.abc") { alphabetical = true }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down").frame(width: 44, height: 44)
                    }.accessibilityLabel("Sort subscriptions")
                }
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(DueTheme.secondary)
                    TextField("Search subscriptions", text: $search).accessibilityIdentifier(
                        "subscriptionSearch")
                    if !search.isEmpty {
                        Button {
                            search = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }.accessibilityLabel("Clear search")
                    }
                }.padding(15).background(DueTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                Picker("Filter subscriptions", selection: $filter) {
                    ForEach(SubscriptionFilter.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                if items.isEmpty {
                    EmptyState(
                        symbol: "square.stack",
                        title: search.isEmpty ? "Nothing here yet" : "No matching subscriptions",
                        message: search.isEmpty
                            ? "Add a plan or free trial to keep its next charge in view."
                            : "Try a different name or category.")
                    if search.isEmpty {
                        Button("Add subscription", action: add).buttonStyle(PrimaryButton())
                    }
                } else {
                    Surface(padding: 16) {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                if index > 0 { Divider().padding(.leading, 62) }
                                Button {
                                    select(item)
                                } label: {
                                    SubscriptionRow(item: item)
                                }.buttonStyle(.plain)
                                    .accessibilityIdentifier("subscription-\(item.name)")
                            }
                        }
                    }
                }
            }.padding(24).frame(maxWidth: 640).frame(maxWidth: .infinity)
        }.background(DueTheme.canvas).navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: add) { Image(systemName: "plus") }.accessibilityLabel(
                        "Add subscription")
                }
            }
    }
}

private enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case trials = "Trials"
    case cancelled = "Cancelled"

    var id: Self { self }

    func includes(_ subscription: Subscription) -> Bool {
        switch self {
        case .all: subscription.status != .archived
        case .active: subscription.status == .active
        case .trials: subscription.status == .trial
        case .cancelled: subscription.status == .archived
        }
    }
}

#if DEBUG
    #Preview("Subscriptions") {
        PreviewContainer {
            NavigationStack { SubscriptionsView(add: {}, select: { _ in }) }
        }
    }
#endif
