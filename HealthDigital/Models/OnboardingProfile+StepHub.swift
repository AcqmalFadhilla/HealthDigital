//
//  OnboardingProfile+StepHub.swift
//  HealthDigital
//
//  Step Hub reads everything from the profile collected by the onboarding flow
//  (Onboarding/OnboardingProfile.swift). These helpers adapt it for the hub,
//  the menu bar reminder and Settings without duplicating any of its data.
//

import Foundation

extension OnboardingProfile {
    /// Daily goal in steps.
    var dailyGoal: Int {
        get { dailyStepGoal }
        set { dailyStepGoal = newValue }
    }

    /// Activities the daily reminder can suggest.
    var activities: Set<SuggestedActivity> {
        get { suggestedActivities }
        set { suggestedActivities = newValue }
    }

    /// Goal recommended for this age and activity level (same rule onboarding uses).
    var recommendedGoal: Int {
        StepGuidance.recommendedGoal(for: age, activityLevel: activityLevel)
    }

    /// Reminder time as minutes after midnight.
    var reminderMinutes: Int {
        get {
            let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            return (c.hour ?? 19) * 60 + (c.minute ?? 0)
        }
        set {
            reminderTime = Calendar.current.date(from: DateComponents(hour: newValue / 60, minute: newValue % 60)) ?? reminderTime
        }
    }

    /// Read-only view of the reminder schedule.
    var reminder: ReminderSchedule {
        ReminderSchedule(isEnabled: reminderEnabled, minutesAfterMidnight: reminderMinutes, days: reminderDays)
    }
}

struct ReminderSchedule: Equatable {
    var isEnabled: Bool
    var minutesAfterMidnight: Int
    var days: Set<Weekday>

    var timeLabel: String { Clock.label(minutes: minutesAfterMidnight) }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        isEnabled && days.contains(Weekday(date: date, calendar: calendar))
    }

    func fireDate(on date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: minutesAfterMidnight / 60, minute: minutesAfterMidnight % 60, second: 0, of: date) ?? date
    }
}

extension Weekday {
    /// Maps Calendar's weekday (1 = Sunday … 7 = Saturday) onto Monday-first `Weekday`.
    init(date: Date, calendar: Calendar = .current) {
        let w = calendar.component(.weekday, from: date)
        self = Weekday(rawValue: w == 1 ? 7 : w - 1) ?? .monday
    }
}

extension SuggestedActivity {
    /// What the reminder asks the user to do.
    var prompt: String {
        switch self {
        case .shortWalk: "Take a 10-minute brisk walk"
        case .takeStairs: "Take the stairs up and down a few floors"
        case .refillWater: "Refill your water on another floor"
        case .standingCall: "Take your next call standing and pacing"
        case .stretchBreak: "Stand up for a 2-minute stretch"
        case .walkToColleague: "Walk over to a colleague instead of messaging"
        }
    }

    var minutes: Int {
        switch self {
        case .shortWalk: 10
        case .takeStairs: 5
        case .refillWater: 4
        case .standingCall: 10
        case .stretchBreak: 2
        case .walkToColleague: 5
        }
    }

    /// Rough expected steps, only for the suggestion text. Real credit comes from the Watch.
    var estimatedSteps: Int {
        switch self {
        case .shortWalk: 1_000
        case .takeStairs: 400
        case .refillWater: 300
        case .standingCall: 1_000
        case .stretchBreak: 50
        case .walkToColleague: 250
        }
    }

    var estimateLabel: String { "≈ \(estimatedSteps.grouped) steps" }
    var symbol: String { symbolName }

    /// Today's activity from the user's picks. Rotates by day; `offset` comes from "Different activity".
    static func activity(for date: Date, from picks: Set<SuggestedActivity>, offset: Int = 0, calendar: Calendar = .current) -> SuggestedActivity? {
        let ordered = allCases.filter(picks.contains)
        guard !ordered.isEmpty else { return nil }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return ordered[(day + offset) % ordered.count]
    }
}

enum Clock {
    static func label(minutes: Int) -> String {
        String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }

    static func label(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return label(minutes: (c.hour ?? 0) * 60 + (c.minute ?? 0))
    }
}

extension Int {
    /// 5140 → "5,140"
    var grouped: String { formatted(.number.grouping(.automatic)) }
}
