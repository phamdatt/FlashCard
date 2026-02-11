//
//  ReviewReminderManager.swift
//  flash-card
//
//  Schedules a daily local notification: "Có X từ cần ôn hôm nay". User can enable/disable in Cài đặt.
//

import Foundation
import UserNotifications

private let reviewReminderEnabledKey = "reviewReminderEnabled"
private let reviewReminderHourKey = "reviewReminderHour"
private let reviewReminderMinuteKey = "reviewReminderMinute"
private let pendingOpenReviewFromNotificationKey = "pendingOpenReviewFromNotification"
private let lastScheduleTimeKey = "reviewReminderLastScheduleTime"
private let scheduleCooldownSeconds: TimeInterval = 300

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

    /// Giờ nhắc ôn (0–23). Mặc định 9.
    static var reminderHour: Int {
        get { UserDefaults.standard.object(forKey: reviewReminderHourKey) as? Int ?? 9 }
        set { UserDefaults.standard.set(newValue, forKey: reviewReminderHourKey) }
    }
    /// Phút nhắc ôn (0–59). Mặc định 0.
    static var reminderMinute: Int {
        get { UserDefaults.standard.object(forKey: reviewReminderMinuteKey) as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: reviewReminderMinuteKey) }
    }

    /// Call when app becomes active: chỉ schedule nếu đã quá 5 phút kể từ lần trước (tránh spam khi chuyển app liên tục).
    static func scheduleReminderIfNeeded() {
        guard isEnabled else { return }
        let now = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: lastScheduleTimeKey)
        guard now - last >= scheduleCooldownSeconds else { return }
        scheduleReminder()
    }

    static func scheduleReminder() {
        guard isEnabled else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastScheduleTimeKey)
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

        var date = DateComponents()
        date.hour = reminderHour
        date.minute = reminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }

    /// Set when user taps the review notification; ContentView clears it after switching to review.
    static var pendingOpenReviewFromNotification: Bool {
        get { UserDefaults.standard.bool(forKey: pendingOpenReviewFromNotificationKey) }
        set { UserDefaults.standard.set(newValue, forKey: pendingOpenReviewFromNotificationKey) }
    }
}
