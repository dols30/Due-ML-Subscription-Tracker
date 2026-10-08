//
//  SubscriptionEditor.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct SubscriptionEditor: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let existing: Subscription?
    @State private var draft: SubscriptionDraft
    @State private var browsingServices = false
    @State private var describing = false
    @State private var description = ""
    @State private var importedEntry = false
    @State private var checkedEntry = false
    @State private var unresolved: Set<EntryReviewField> = []
    @State private var validation: String?
    @FocusState private var focused: Bool

    init(existing: Subscription? = nil) {
        self.existing = existing
        _draft = State(initialValue: SubscriptionDraft(subscription: existing))
    }

    var body: some View {
        NavigationStack {
            Form {
                if existing == nil {
                    ServiceSelectionSection(
                        browse: { browsingServices = true },
                        enterManually: { focused = true },
                        describe: { describing = true })
                }
                if importedEntry { entryReviewSection }
                serviceSection
                billingSection
                reminderSection
                detailsSection
            }.scrollContentBackground(.hidden).background(DueTheme.canvas)
                .navigationTitle(existing == nil ? "Add subscription" : "Edit subscription")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save).fontWeight(.semibold).accessibilityIdentifier(
                            "saveSubscription"
                        )
                        .disabled(importedEntry && (!checkedEntry || !unresolved.isEmpty))
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            focused = false
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
                                for: nil)
                        }
                    }
                }
                .alert(
                    "Check the details",
                    isPresented: Binding(
                        get: { validation != nil }, set: { if !$0 { validation = nil } })
                ) {
                    Button("OK") { validation = nil }
                } message: {
                    Text(validation ?? "")
                }
        }
        .sheet(isPresented: $browsingServices) {
            ServiceBrowser { service in
                applyPreset(service)
                browsingServices = false
            }
        }
        .sheet(isPresented: $describing) {
            NaturalEntryView(
                description: $description,
                apply: { suggestion in
                    draft = suggestion.draft
                    unresolved = suggestion.unresolved
                    importedEntry = true
                    checkedEntry = false
                    describing = false
                },
                enterManually: {
                    describing = false
                    focused = true
                })
        }
    }

    private var entryReviewSection: some View {
        Section {
            Toggle("I’ve checked the suggested details", isOn: $checkedEntry)
                .accessibilityIdentifier("confirmEntryDetails")
        } header: {
            Text("Review your entry").textCase(nil)
        } footer: {
            Text(
                unresolved.isEmpty
                    ? "You can edit any detail before saving."
                    : "Choose the missing details below before saving.")
        }
    }

    private var serviceSection: some View {
        Section {
            TextField("Service name", text: $draft.name).textContentType(.organizationName).focused(
                $focused
            ).accessibilityIdentifier("serviceName")
            Picker("Category", selection: $draft.category) {
                ForEach(ServiceCategory.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Plan type", selection: reviewed(\.status, field: .planType)) {
                if unresolved.contains(.planType) {
                    Text("Choose plan type").tag(Optional<SubscriptionStatus>.none)
                }
                Text("Paid subscription").tag(Optional(SubscriptionStatus.active))
                Text("Free trial").tag(Optional(SubscriptionStatus.trial))
                if existing?.status == .archived {
                    Text("Cancelled").tag(Optional(SubscriptionStatus.archived))
                }
            }.accessibilityIdentifier("planType")
        } header: {
            Text("Service").textCase(nil)
        }
    }

    private var billingSection: some View {
        Section {
            HStack {
                Text(draft.status == .trial ? "Price after trial" : "Price")
                Spacer()
                TextField("0.00", text: $draft.amount).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).frame(maxWidth: 130).accessibilityIdentifier(
                        "price")
            }
            Picker("Currency", selection: $draft.currency) {
                if draft.currency.isEmpty { Text("Choose currency").tag("") }
                ForEach(Money.currencies, id: \.self) { Text($0).tag($0) }
            }
            .accessibilityIdentifier("entryCurrency")
            .onChange(of: draft.currency) { _, value in
                if Money.currencies.contains(value) { unresolved.remove(.currency) }
            }
            Picker("Billing cycle", selection: reviewed(\.cycle, field: .cycle)) {
                if unresolved.contains(.cycle) {
                    Text("Choose cycle").tag(Optional<BillingCycle>.none)
                }
                ForEach(BillingCycle.allCases) { Text($0.title).tag(Optional($0)) }
            }
            DatePicker(
                draft.status == .trial ? "Trial ends" : "Billing date", selection: $draft.date,
                displayedComponents: .date
            )
            .onChange(of: draft.date) { _, _ in unresolved.remove(.date) }
            if unresolved.contains(.date) {
                Button("Use date: \(draft.date.formatted(date: .long, time: .omitted))") {
                    unresolved.remove(.date)
                }
                .accessibilityIdentifier("confirmEntryDate")
                Text("Set the date above, or confirm the date shown.")
                    .font(.footnote).foregroundStyle(DueTheme.secondary)
            }
        } header: {
            Text("Billing").textCase(nil)
        } footer: {
            Text(
                draft.status == .trial
                    ? "Your trial stays flagged until you mark it paid or cancelled."
                    : "Use a billing date from your plan. Future renewals follow this date, including monthly and yearly cycles."
            )
        }
    }

    private var reminderSection: some View {
        Section {
            Picker("Remind me", selection: reviewed(\.reminderDays, field: .reminder)) {
                if unresolved.contains(.reminder) {
                    Text("Choose reminder").tag(Optional<Int>.none)
                }
                Text("On the day").tag(Optional(0))
                Text("1 day before").tag(Optional(1))
                Text("2 days before").tag(Optional(2))
                Text("3 days before").tag(Optional(3))
                Text("7 days before").tag(Optional(7))
                Text("Off").tag(Optional(-1))
            }
        } header: {
            Text("Reminder").textCase(nil)
        } footer: {
            Text(
                "Reminders arrive at 9:00 AM, with a second reminder on the charge date. Notification access is requested when you save."
            )
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("https://…", text: $draft.managementURL).keyboardType(.URL)
                .textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityLabel(
                    "Manage subscription link")
            TextField(
                "Notes, shared plan, or cancellation steps", text: $draft.notes, axis: .vertical
            ).lineLimit(3...6)
        } header: {
            Text("Details (optional)").textCase(nil)
        } footer: {
            Text("Add the service’s account page so it’s easy to manage later.")
        }
    }

    private func reviewed<Value: Hashable>(
        _ keyPath: WritableKeyPath<SubscriptionDraft, Value>,
        field: EntryReviewField
    ) -> Binding<Value?> {
        Binding(
            get: { unresolved.contains(field) ? nil : draft[keyPath: keyPath] },
            set: { value in
                guard let value else { return }
                draft[keyPath: keyPath] = value
                unresolved.remove(field)
            })
    }

    private func applyPreset(_ preset: ServicePreset) {
        draft.name = preset.name
        draft.category = preset.category
        draft.managementURL = preset.managementURL
    }

    private func save() {
        do {
            let subscription = try draft.subscription(replacing: existing)
            store.save(subscription)
            if draft.reminderDays >= 0 && store.remindersEnabled {
                Task { await store.requestReminders() }
            }
            dismiss()
        } catch {
            validation = error.localizedDescription
        }
    }
}

#if DEBUG
    #Preview("Add subscription") {
        PreviewContainer {
            SubscriptionEditor()
        }
    }
#endif
