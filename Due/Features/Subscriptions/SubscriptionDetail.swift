//
//  SubscriptionDetail.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct SubscriptionDetail: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let itemID: UUID
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize = 40
    @State private var editing = false
    @State private var confirmDelete = false
    @State private var confirmCancel = false
    private var item: Subscription? { store.subscriptions.first { $0.id == itemID } }
    var body: some View {
        NavigationStack {
            if let item {
                ScrollView {
                    VStack(spacing: 24) {
                        header(for: item)
                        if item.status != .archived {
                            Surface {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.status == .trial ? "Trial ends" : "Next charge")
                                            .font(.subheadline).foregroundStyle(DueTheme.secondary)
                                        Text(
                                            item.nextCharge().formatted(
                                                .dateTime.month(.wide).day().year())
                                        ).font(.headline)
                                    }
                                    Spacer()
                                    VStack(spacing: 2) {
                                        Text(
                                            item.daysRemaining() < 0
                                                ? "Ended" : "\(item.daysRemaining())"
                                        ).font(
                                            .system(.title2, weight: .semibold))
                                        if item.daysRemaining() >= 0 {
                                            Text("days left").font(.caption)
                                        }
                                    }.foregroundStyle(DueTheme.accent)
                                }
                            }
                            Surface {
                                HStack(spacing: 14) {
                                    Image(
                                        systemName: item.reminderDays == nil
                                            ? "bell.slash" : "bell.badge"
                                    ).font(.title3).foregroundStyle(DueTheme.accent)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(reminderTitle(item)).font(
                                            .subheadline.weight(.semibold))
                                        Text(reminderCaption).font(.caption).foregroundStyle(
                                            DueTheme.secondary)
                                    }
                                }
                            }
                        }
                        if !item.notes.isEmpty {
                            Surface {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Notes").font(.headline)
                                    Text(item.notes).font(.body).foregroundStyle(DueTheme.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        if let url = URL(string: item.managementURL),
                            ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
                            url.host != nil
                        {
                            Link(destination: url) {
                                Label("Manage with \(item.name)", systemImage: "arrow.up.right")
                            }.buttonStyle(PrimaryButton())
                        }
                        if item.status == .trial {
                            Button("Keep as paid subscription") {
                                var updated = item
                                updated.status = .active
                                store.save(updated)
                            }.font(.body.weight(.semibold)).padding(.vertical, 10)
                                .accessibilityIdentifier("keepTrial")
                        }
                        if item.status != .archived {
                            Button("Mark as cancelled") { confirmCancel = true }.foregroundStyle(
                                DueTheme.secondary
                            ).padding(.vertical, 8)
                            Text(
                                "This updates your tracker. Cancel billing directly with the service."
                            ).font(.caption).foregroundStyle(DueTheme.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Button("Reactivate plan") {
                                var updated = item
                                updated.status = .active
                                store.save(updated)
                            }.buttonStyle(PrimaryButton())
                        }
                        Button("Delete subscription", role: .destructive) { confirmDelete = true }
                            .font(.subheadline).padding(.vertical, 16)
                    }.padding(24).frame(maxWidth: 640).frame(maxWidth: .infinity)
                }.background(DueTheme.canvas).navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Edit") { editing = true }.accessibilityIdentifier(
                                "editSubscription")
                        }
                    }
                    .sheet(isPresented: $editing) { SubscriptionEditor(existing: item) }
                    .confirmationDialog(
                        "Delete \(item.name)?", isPresented: $confirmDelete,
                        titleVisibility: .visible
                    ) {
                        Button("Delete subscription", role: .destructive) {
                            store.deleteSubscription(id: item.id)
                            dismiss()
                        }
                    } message: {
                        Text(
                            "This removes the plan and its reminders from Due. It won’t cancel billing with the service."
                        )
                    }
                    .confirmationDialog(
                        "Mark \(item.name) as cancelled?", isPresented: $confirmCancel,
                        titleVisibility: .visible
                    ) {
                        Button("Mark as cancelled") {
                            var updated = item
                            updated.status = .archived
                            store.save(updated)
                        }
                    } message: {
                        Text(
                            "Confirm that you’ve cancelled with the service. Due can’t cancel it for you."
                        )
                    }
            } else {
                ContentUnavailableView("Subscription removed", systemImage: "square.stack")
            }
        }
    }

    private func header(for item: Subscription) -> some View {
        VStack(spacing: 14) {
            ServiceIcon(item: item, size: 76)
            Text(item.name).font(.system(.title, weight: .bold))
                .multilineTextAlignment(.center)
            Text(item.category.rawValue).font(.subheadline).foregroundStyle(DueTheme.secondary)
            Text(Money.format(item.price, currency: item.currency)).font(
                .system(size: amountSize, weight: .medium)
            )
            Text(billingDescription(for: item)).font(.subheadline).foregroundStyle(
                DueTheme.secondary)
        }.padding(.top, 20)
    }

    private func billingDescription(for item: Subscription) -> String {
        switch item.status {
        case .trial: "\(item.cycle.title.lowercased()) after your free trial"
        case .archived: "Cancelled plan"
        case .active: "Billed \(item.cycle.title.lowercased())"
        }
    }

    private func reminderTitle(_ item: Subscription) -> String {
        guard let days = item.reminderDays else { return "No reminder" }
        return days == 0 ? "On the charge date" : "\(days) \(days == 1 ? "day" : "days") before"
    }

    private var reminderCaption: String {
        if !store.remindersEnabled { return "Reminders are paused in Settings" }
        if store.notificationStatus != .authorized && store.notificationStatus != .provisional {
            return "Enable notification access in Settings"
        }
        return "At 9:00 AM, plus a reminder on the day"
    }
}
