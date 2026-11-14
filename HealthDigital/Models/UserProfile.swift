//
//  UserProfile.swift
//  HealthDigital
//
//  Everything the user sets in onboarding. All of it can be changed later in Settings.
//

import Foundation

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male, female, nonBinary, preferNotToSay
    var id: Self { self }

    var label: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .nonBinary: "Non-binary"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary, lightlyActive, moderatelyActive, veryActive
    var id: Self { self }

    var label: String {
        switch self {
        case .sedentary: "Sedentary"
        case .lightlyActive: "Lightly active"
        case .moderatelyActive: "Moderately active"
        case .veryActive: "Very active"
        }
    }

    var detail: String {
        switch self {
        case .sedentary: "Sitting most of the day, little walking"
        case .lightlyActive: "Some walking — to meetings, lunch, commute"
        case .moderatelyActive: "On your feet often, or a regular workout"
        case .veryActive: "Physically active job or daily intense exercise"
        }
    }

    /// Starting goal suggested in onboarding. Product placeholder values — confirm in the PRD.
    var suggestedGoal: Int {
        switch self {
        case .sedentary: 5_000
        case .lightlyActive: 7_500
        case .moderatelyActive: 10_000
        case .veryActive: 12_000
        }
    }
}

enum Motivation: String, Codable, CaseIterable, Identifiable {
    case energy, stiffness, weight, longTerm, habit, doctor
    var id: Self { self }

    var label: String {
        switch self {
        case .energy: "Feel more energetic"
        case .stiffness: "Ease back and neck stiffness"
        case .weight: "Manage my weight"
        case .longTerm: "Stay healthy long-term"
        case .habit: "Build a daily habit"
        case .doctor: "Advice from my doctor"
        }
    }
}

struct ReminderSettings: Codable, Equatable {
    var isEnabled = true
    /// Minutes after midnight, e.g. 14:00 = 840.
    var minutesAfterMidnight = 14 * 60
    /// Calendar weekday numbers: 1 = Sunday … 7 = Saturday.
    var activeWeekdays: Set<Int> = [2, 3, 4, 5, 6]

    var hour: Int { minutesAfterMidnight / 60 }
    var minute: Int { minutesAfterMidnight % 60 }
    var timeLabel: String { Clock.label(minutes: minutesAfterMidnight) }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        isEnabled && activeWeekdays.contains(calendar.component(.weekday, from: date))
    }

    func fireDate(on date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
}

struct UserProfile: Codable, Equatable {
    var name = ""
    var age: Int?
    var gender: Gender = .preferNotToSay
    var heightCm: Double?
    var weightKg: Double?
    var activityLevel: ActivityLevel = .lightlyActive
    var dailyGoal = ActivityLevel.lightlyActive.suggestedGoal
    var motivations: Set<Motivation> = []
    var activities: Set<StepActivity> = [.shortWalk, .takeStairs, .refillWater]
    var reminder = ReminderSettings()
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
