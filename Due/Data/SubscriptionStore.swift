//
//  SubscriptionStore.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation
import Observation
import UserNotifications

@MainActor @Observable
final class SubscriptionStore {
    private(set) var subscriptions: [Subscription] = []
    var errorMessage: String?
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    var remindersEnabled: Bool {
        didSet {
            defaults.set(remindersEnabled, forKey: "remindersEnabled")
            Task { await refreshReminders() }
        }
    }
    private let file: SubscriptionFile
    private let defaults: UserDefaults
    private let isTemporary: Bool
    private let reminderScheduler = ReminderScheduler()

    init(fileURL: URL? = nil, defaults: UserDefaults = .standard, isTemporary: Bool = false) {
        self.defaults = defaults
        self.isTemporary = isTemporary
        remindersEnabled = defaults.object(forKey: "remindersEnabled") as? Bool ?? true
        file = SubscriptionFile(url: fileURL)
        do {
            subscriptions = try file.load()
        } catch {
            errorMessage =
                "Your saved subscriptions couldn’t be opened. The original file has been kept. A recovery copy will be preserved before you save new entries."
        }
    }

    var currentSubscriptions: [Subscription] { subscriptions.filter { $0.status != .archived } }
    var trialSubscriptions: [Subscription] {
        currentSubscriptions.filter { $0.status == .trial }.sorted {
            $0.billingDate < $1.billingDate
        }
    }

    var upcomingSubscriptions: [Subscription] {
        currentSubscriptions.sorted { $0.nextCharge() < $1.nextCharge() }
    }

    func save(_ item: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == item.id }) {
            subscriptions[index] = item
        } else {
            subscriptions.append(item)
        }
        persist()
        Task { await refreshReminders() }
    }

    func deleteSubscription(id: UUID) {
        subscriptions.removeAll { $0.id == id }
        persist()
        Task { await refreshReminders() }
    }

    private func persist() {
        guard !isTemporary else { return }
        do {
            try file.save(subscriptions)
        } catch {
            errorMessage =
                "This change couldn’t be saved. Please check your device’s available storage and try again."
        }
    }

    func refreshNotificationStatus() async {
        guard !isTemporary else { return }
        notificationStatus = await UNUserNotificationCenter.current().notificationSettings()
            .authorizationStatus
    }

    func requestReminders() async {
        guard !isTemporary else { return }
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [
                .alert, .sound, .badge,
            ])
            await refreshNotificationStatus()
            await refreshReminders()
        } catch { errorMessage = "Reminders couldn’t be enabled. You can try again in Settings." }
    }

    func refreshReminders() async {
        guard !isTemporary else { return }
        await refreshNotificationStatus()
        do {
            try await reminderScheduler.schedule(currentSubscriptions, enabled: remindersEnabled)
        } catch {
            errorMessage =
                "A reminder couldn’t be scheduled. Open Settings to check notification access."
        }
    }
}
