//
//  RootView.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct EditorRoute: Identifiable {
    let id = UUID()
    var item: Subscription?
}

struct RootView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = AppTab.overview
    @State private var editor: EditorRoute?
    @State private var selected: Subscription?
    var body: some View {
        @Bindable var store = store
        TabView(selection: $tab) {
            NavigationStack {
                OverviewView(add: { editor = EditorRoute() }, select: { selected = $0 })
            }
            .tabItem { Label("Overview", systemImage: "square.grid.2x2") }.tag(AppTab.overview)
            NavigationStack {
                SubscriptionsView(add: { editor = EditorRoute() }, select: { selected = $0 })
            }
            .tabItem { Label("Subscriptions", systemImage: "square.stack") }.tag(
                AppTab.subscriptions)
            NavigationStack { BillingCalendarView(select: { selected = $0 }) }
                .tabItem { Label("Calendar", systemImage: "calendar") }.tag(AppTab.calendar)
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(
                    AppTab.settings)
        }
        .sheet(item: $editor) { route in SubscriptionEditor(existing: route.item) }
        .sheet(item: $selected) { item in SubscriptionDetail(itemID: item.id) }
        .alert(
            "Couldn’t complete this action",
            isPresented: Binding(
                get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
        ) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .task {
            NotificationRouter.shared.onOpen = { id in
                selected = store.subscriptions.first { $0.id == id }
            }
            if let id = NotificationRouter.shared.pendingID {
                selected = store.subscriptions.first { $0.id == id }
                NotificationRouter.shared.pendingID = nil
            }
            await store.refreshNotificationStatus()
            await store.refreshReminders()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.refreshReminders() } }
        }
    }
}

private enum AppTab {
    case overview, subscriptions, calendar, settings
}

#if DEBUG
    #Preview("Due") {
        PreviewContainer {
            RootView()
        }
    }
#endif
