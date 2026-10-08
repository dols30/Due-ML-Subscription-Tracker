//
//  NotificationRouter.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation
import UserNotifications

final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    var onOpen: ((UUID) -> Void)?
    var pendingID: UUID?
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        guard
            let value = response.notification.request.content.userInfo["subscriptionID"] as? String,
            let id = UUID(uuidString: value)
        else { return }
        await MainActor.run {
            if let onOpen = self.onOpen { onOpen(id) } else { self.pendingID = id }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions { [.banner, .sound] }
}
