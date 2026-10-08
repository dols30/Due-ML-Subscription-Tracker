//
//  DueApp.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI
import UserNotifications

@main
struct DueApp: App {
    @State private var store: SubscriptionStore
    init() {
        let testing = ProcessInfo.processInfo.arguments.contains("-uitesting")
        let subscriptionStore = SubscriptionStore(
            fileURL: testing
                ? FileManager.default.temporaryDirectory.appending(
                    path: UUID().uuidString + ".json") : nil, isTemporary: testing)
        _store = State(initialValue: subscriptionStore)
        UNUserNotificationCenter.current().delegate = NotificationRouter.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView().environment(store).tint(DueTheme.accent)
                .preferredColorScheme(.dark)
        }
    }
}
