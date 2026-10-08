//
//  ServiceSelectionSection.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct ServiceSelectionSection: View {
    let browse: () -> Void
    let enterManually: () -> Void
    let describe: () -> Void

    var body: some View {
        Section {
            Button(action: describe) {
                Label("Describe your subscription", systemImage: "text.bubble")
            }
            .accessibilityIdentifier("describeSubscription")
            Button(action: browse) {
                Label("Browse services", systemImage: "magnifyingglass")
            }
            .accessibilityIdentifier("browseServices")
            Button(action: enterManually) {
                Label("Add manually", systemImage: "square.and.pencil")
            }
            .accessibilityIdentifier("addManually")
        }
    }
}

struct ServiceBrowser: View {
    let select: (ServicePreset) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var services: [ServicePreset] {
        ServicePreset.all.filter { service in
            search.isEmpty || service.name.localizedCaseInsensitiveContains(search)
                || service.category.rawValue.localizedCaseInsensitiveContains(search)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                if services.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else {
                    ForEach(services) { service in
                        Button {
                            select(service)
                        } label: {
                            HStack(spacing: 14) {
                                ServiceIcon(
                                    item: Subscription(
                                        name: service.name, price: 0, billingDate: .now,
                                        category: service.category),
                                    size: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(service.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(DueTheme.ink)
                                    Text(service.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(DueTheme.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus")
                                    .foregroundStyle(DueTheme.accent)
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityIdentifier("servicePreset-\(service.id)")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DueTheme.canvas)
            .navigationTitle("Browse services")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $search, placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name or category"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
    #Preview("Browse services") {
        PreviewContainer {
            ServiceBrowser(select: { _ in })
        }
    }
#endif
