//
//  SettingsView.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var exportURL: URL?
    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                HStack(spacing: 15) {
                    Image(systemName: "circle.hexagongrid.fill").font(.system(size: 29))
                        .foregroundStyle(DueTheme.accent)
                        .frame(width: 62, height: 62).background(
                            DueTheme.softBlue, in: RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Due").font(.system(.title2, weight: .bold))
                        Text("A clearer view of your subscriptions.").font(.subheadline)
                            .foregroundStyle(DueTheme.secondary)
                    }
                }.padding(.vertical, 12)
            }
            Section {
                Toggle("Subscription reminders", isOn: $store.remindersEnabled).tint(DueTheme.blue)
                    .onChange(of: store.remindersEnabled) { _, enabled in
                        if enabled { Task { await store.requestReminders() } }
                    }
                HStack {
                    Text("Notification access")
                    Spacer()
                    Text(permissionLabel).foregroundStyle(DueTheme.secondary)
                }
                if store.notificationStatus == .notDetermined {
                    Button("Enable notifications") { Task { await store.requestReminders() } }
                } else if store.notificationStatus == .denied {
                    Button("Open iPhone settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            } header: {
                Text("Reminders").textCase(nil)
            } footer: {
                Text(
                    "Choose each plan’s reminder timing when you add or edit it. Reminders arrive at 9:00 AM and on the charge date. Due schedules the nearest 60 reminders; opening the app refreshes the schedule."
                )
            }
            Section {
                Label("Stored on this device", systemImage: "iphone")
                Label("No account or bank linking", systemImage: "lock.shield")
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share subscription file", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        export()
                    } label: {
                        Label("Export subscriptions as CSV", systemImage: "square.and.arrow.up")
                    }.disabled(store.subscriptions.isEmpty)
                }
            } header: {
                Text("Your data").textCase(nil)
            } footer: {
                Text(
                    "Due doesn’t connect to your bank or send your entries to a server. Export a copy to keep a backup. Different currencies are never combined or converted."
                )
            }
            Section {
                Text(
                    "Due tracks dates you enter. It can’t detect payments or cancel services. Check the service’s own billing terms when you make changes."
                ).font(.subheadline).foregroundStyle(DueTheme.secondary)
            }
        }.scrollContentBackground(.hidden).background(DueTheme.canvas).navigationTitle("Settings")
            .task { await store.refreshNotificationStatus() }
            .onChange(of: store.subscriptions) { _, _ in exportURL = nil }
    }

    private var permissionLabel: String {
        switch store.notificationStatus {
        case .authorized, .provisional, .ephemeral: "Enabled"
        case .denied: "Off"
        case .notDetermined: "Not enabled"
        @unknown default: "Unknown"
        }
    }

    private func export() {
        do {
            exportURL = try SubscriptionExporter.export(store.subscriptions)
        } catch {
            store.errorMessage = "The export couldn’t be created. Please try again."
        }
    }
}

#if DEBUG
    #Preview("Settings") {
        PreviewContainer {
            NavigationStack { SettingsView() }
        }
    }
#endif
