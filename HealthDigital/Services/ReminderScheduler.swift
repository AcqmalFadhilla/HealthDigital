//
//  ReminderScheduler.swift
//  HealthDigital
//
//  One local notification per active day at the user's reminder time, naming that day's
//  activity. The notification has a "Yes, I'm doing it now" action that starts the activity.
//

import Foundation
import UserNotifications

@MainActor
final class ReminderScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let categoryID = "DAILY_ACTIVITY"
    static let startActionID = "START_ACTIVITY"
    static let notNowActionID = "NOT_NOW"
    private static let idPrefix = "daily-reminder-"

    /// Called when the user taps "Yes, I'm doing it now" on the notification.
    var onStart: (() -> Void)?
    /// Called when the notification fires while the app is running.
    var onFire: (() -> Void)?

    private let center = UNUserNotificationCenter.current()

    func configure() {
        center.delegate = self
        let start = UNNotificationAction(identifier: Self.startActionID, title: "Yes, I’m doing it now", options: [.foreground])
        let notNow = UNNotificationAction(identifier: Self.notNowActionID, title: "Not now")
        let category = UNNotificationCategory(identifier: Self.categoryID, actions: [start, notNow], intentIdentifiers: [])
        center.setNotificationCategories([category])
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Replaces pending reminders with one per active day for the next week.
    func reschedule(profile: UserProfile, session: ActivitySession, now: Date = Date()) {
        let calendar = Calendar.current
        var requests: [UNNotificationRequest] = []
        for dayOffset in 0..<7 where profile.reminder.isEnabled {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)),
                  profile.reminder.isActive(on: day, calendar: calendar) else { continue }
            let fire = profile.reminder.fireDate(on: day, calendar: calendar)
            guard fire > now else { continue }
            let isToday = dayOffset == 0
            if isToday && session.phase != .waiting { continue }

            let offset = isToday ? session.activityOffset : 0
            let content = UNMutableNotificationContent()
            content.title = "Time to move"
            if let activity = StepActivity.activity(for: day, from: profile.activities, offset: offset, calendar: calendar) {
                content.body = "\(activity.prompt). \(activity.estimateLabel)."
            } else {
                content.body = "Stand up and stretch for a few minutes."
            }
            content.categoryIdentifier = Self.categoryID
            content.sound = .default

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            requests.append(UNNotificationRequest(identifier: Self.idPrefix + ActivitySession.key(for: day), content: content, trigger: trigger))
        }

        Task {
            let pending = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) })
            for request in requests { try? await center.add(request) }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await MainActor.run { onFire?() }
        return [.banner, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        await MainActor.run {
            if action == Self.startActionID { onStart?() } else { onFire?() }
        }
    }
}
