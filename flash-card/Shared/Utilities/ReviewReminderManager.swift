//
//  ReviewReminderManager.swift
//  flash-card
//
//  Schedules a daily local notification: "Có X từ cần ôn hôm nay". User can enable/disable in Cài đặt.
//

import Foundation
import UserNotifications

private let reviewReminderEnabledKey = "reviewReminderEnabled"

enum ReviewReminderManager {
    /// Identifier của notification nhắc ôn (để AppDelegate biết khi user bấm vào).
    static let notificationIdentifier = "flash-card.reviewReminder"
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: reviewReminderEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: reviewReminderEnabledKey)
            if newValue {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    /// Call when app becomes active or when user toggles on: request permission and schedule next notification with current due count.
    static func scheduleReminderIfNeeded() {
        guard isEnabled else { return }
        scheduleReminder()
    }

    static func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                _scheduleOne()
            }
        }
    }

    private static func _scheduleOne() {
        cancelReminder()
        let dueCount = DatabaseManager.shared.getDueFlashcards().count
        let content = UNMutableNotificationContent()
        content.title = "Ôn tập từ vựng"
        content.body = dueCount > 0 ? "Có \(dueCount) từ cần ôn hôm nay." : "Hôm nay không có từ cần ôn."
        content.sound = .default

        // Hard: nhắc sau 5 phút, lặp lại mỗi 5 phút (để test).
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: true)

        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}
