//
//  ActivitySession.swift
//  HealthDigital
//
//  State of today's single reminder + activity. Resets each day.
//

import Foundation

struct ActivitySession: Codable, Equatable {
    enum Phase: String, Codable {
        /// Reminder time hasn't come yet (or no reminder today).
        case waiting
        /// Reminder fired; waiting for "Yes, I'm doing it now".
        case notified
        /// User is doing the activity; steps since `startedAt` are credited to it.
        case inProgress
        /// User tapped Done.
        case completed
    }

    var dayKey: String
    var phase: Phase = .waiting
    /// Added by "Different activity" so the rotation moves on for today only.
    var activityOffset = 0
    var startedAt: Date?
    var completedAt: Date?
    /// Steps credited to the activity (from the Watch, between start and Done).
    var creditedSteps = 0

    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func fresh(for date: Date) -> ActivitySession {
        ActivitySession(dayKey: key(for: date))
    }
}
