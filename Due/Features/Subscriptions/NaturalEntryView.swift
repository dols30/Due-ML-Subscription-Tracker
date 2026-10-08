//
//  NaturalEntryView.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/8/26.
//

import SwiftUI

struct NaturalEntryView: View {
    @Binding var description: String
    let apply: (EntrySuggestion) -> Void
    let enterManually: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var interpreting = false
    @State private var error: String?
    @State private var task: Task<Void, Never>?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Describe one subscription…", text: $description, axis: .vertical)
                        .lineLimit(5...8)
                        .focused($focused)
                        .accessibilityIdentifier("subscriptionDescription")
                } header: {
                    Text("Subscription details").textCase(nil)
                } footer: {
                    Text(
                        "For example: Netflix costs 15.99 USD per month, renews October 25, and remind me two days before."
                    )
                }
                Section {
                    Button(action: interpret) {
                        HStack {
                            Text(interpreting ? "Reading details…" : "Review details")
                            Spacer()
                            if interpreting {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.right")
                            }
                        }
                    }
                    .disabled(
                        interpreting
                            || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                    .accessibilityIdentifier("interpretSubscription")
                } footer: {
                    Text("Check the suggested details before saving.")
                }
                if let error {
                    Section {
                        Text(error).foregroundStyle(DueTheme.secondary)
                        Button("Enter manually", action: enterManually)
                            .accessibilityIdentifier("entryManualFallback")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DueTheme.canvas)
            .navigationTitle("Describe your subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
        }
        .onDisappear { task?.cancel() }
    }

    private func interpret() {
        focused = false
        interpreting = true
        error = nil
        let text = description
        task = Task {
            do {
                let entities = try await SubscriptionEntryInterpreter.shared.extract(text)
                try Task.checkCancellation()
                let suggestion = try EntryDraftBuilder().suggestion(from: entities)
                interpreting = false
                apply(suggestion)
            } catch is CancellationError {
                interpreting = false
            } catch {
                interpreting = false
                self.error =
                    (error as? EntryError)?.localizedDescription
                    ?? EntryError.modelUnavailable.localizedDescription
            }
        }
    }
}
