//
//  OnboardingProfile.swift
//  StepsGoals
//
//  Created by Training-08 on 14/11/26.
//

import Foundation

/// Gender options collected during onboarding. Used for personalization only.
enum Gender: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case nonBinary
    case preferNotToSay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .nonBinary: "Non-binary"
        case .preferNotToSay: "Prefer not to say"
        }
    }

    var symbolName: String {
        switch self {
        case .male: "figure.stand"
        case .female: "figure.stand.dress"
        case .nonBinary: "person"
        case .preferNotToSay: "person.slash"
        }
    }
}

/// Self-reported activity level, used to recommend a daily step goal.
enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sedentary: "Sedentary"
        case .lightlyActive: "Lightly active"
        case .moderatelyActive: "Moderately active"
        case .veryActive: "Very active"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: "Little to no exercise"
        case .lightlyActive: "Exercise 1–3 days a week"
        case .moderatelyActive: "Exercise 3–5 days a week"
        case .veryActive: "Exercise 6–7 days a week"
        }
    }

    var symbolName: String {
        switch self {
        case .sedentary: "chair"
        case .lightlyActive: "figure.walk"
        case .moderatelyActive: "figure.run"
        case .veryActive: "bolt.fill"
        }
    }
}

/// Reasons the user wants to walk more — shown as multi-select chips.
enum Motivation: String, Codable, CaseIterable, Identifiable {
    case loseWeight = "Lose weight"
    case healthyHabit = "Build a healthy habit"
    case moreEnergy = "Boost my energy"
    case trainForEvent = "Train for an event"
    case mentalWellbeing = "Improve my mood"
    case lookAndFeelGood = "Look & feel good"

    var id: String { rawValue }
    var title: String { rawValue }

    var symbolName: String {
        switch self {
        case .loseWeight: "scalemass"
        case .healthyHabit: "repeat"
        case .moreEnergy: "bolt.fill"
        case .trainForEvent: "medal"
        case .mentalWellbeing: "brain.head.profile"
        case .lookAndFeelGood: "sparkles"
        }
    }
}

/// Everything collected during onboarding. Persisted as JSON in UserDefaults.
struct OnboardingProfile: Codable {
    var name = ""
    var age = 30
    var gender: Gender = .preferNotToSay
    var heightCm: Double = 170
    var weightKg: Double = 70
    var activityLevel: ActivityLevel = .moderatelyActive
    var dailyStepGoal = 10_000
    var motivations: Set<Motivation> = []
    var avatarEmoji = "🔥"
    var reminderEnabled = true
    var reminderTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
    /// Days the reminder is active; all days selected by default.
    var reminderDays: Set<Weekday> = Set(Weekday.allCases)
    /// Activities the user is happy to do — used for "behind on your goal" suggestions.
    var suggestedActivities: Set<SuggestedActivity> = []

    static let `default` = OnboardingProfile()

    /// Explicit memberwise initializer (required because a custom decoder is defined below).
    init(name: String = "", age: Int = 30, gender: Gender = .preferNotToSay, heightCm: Double = 170, weightKg: Double = 70, activityLevel: ActivityLevel = .moderatelyActive, dailyStepGoal: Int = 10_000, motivations: Set<Motivation> = [], avatarEmoji: String = "🔥", reminderEnabled: Bool = true, reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date(), reminderDays: Set<Weekday> = Set(Weekday.allCases), suggestedActivities: Set<SuggestedActivity> = []) {
        self.name = name
        self.age = age
        self.gender = gender
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevel = activityLevel
        self.dailyStepGoal = dailyStepGoal
        self.motivations = motivations
        self.avatarEmoji = avatarEmoji
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.reminderDays = reminderDays
        self.suggestedActivities = suggestedActivities
    }

    private enum CodingKeys: String, CodingKey {
        case name, age, gender, heightCm, weightKg, activityLevel, dailyStepGoal
        case motivations, avatarEmoji, reminderEnabled, reminderTime, reminderDays, suggestedActivities
    }

    /// Custom decoding so profiles saved by older builds (without reminderDays /
    /// suggestedActivities) still load instead of being discarded.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        age = try c.decodeIfPresent(Int.self, forKey: .age) ?? 30
        gender = try c.decodeIfPresent(Gender.self, forKey: .gender) ?? .preferNotToSay
        heightCm = try c.decodeIfPresent(Double.self, forKey: .heightCm) ?? 170
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg) ?? 70
        activityLevel = try c.decodeIfPresent(ActivityLevel.self, forKey: .activityLevel) ?? .moderatelyActive
        dailyStepGoal = try c.decodeIfPresent(Int.self, forKey: .dailyStepGoal) ?? 10_000
        motivations = try c.decodeIfPresent(Set<Motivation>.self, forKey: .motivations) ?? []
        avatarEmoji = try c.decodeIfPresent(String.self, forKey: .avatarEmoji) ?? "🔥"
        reminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? true
        reminderTime = try c.decodeIfPresent(Date.self, forKey: .reminderTime)
            ?? Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
        reminderDays = try c.decodeIfPresent(Set<Weekday>.self, forKey: .reminderDays) ?? Set(Weekday.allCases)
        suggestedActivities = try c.decodeIfPresent(Set<SuggestedActivity>.self, forKey: .suggestedActivities) ?? []
    }

    /// Motivations in stable display order (sets iterate unpredictably).
    var orderedMotivations: [Motivation] {
        Motivation.allCases.filter { motivations.contains($0) }
    }

    /// Imperial helpers shown as secondary labels next to metric values.
    var heightImperial: String {
        let totalInches = heightCm / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches.rounded()) % 12
        return "\(feet)′ \(inches)″"
    }

    var weightImperial: String {
        String(format: "%.0f lb", weightKg * 2.20462)
    }

    /// Deterministic HH:mm label for the reminder time (avoids locale rendering as "19.00").
    var reminderTimeLabel: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        return String(format: "%02d:%02d", components.hour ?? 19, components.minute ?? 0)
    }

    /// Short human-readable reminder schedule, e.g. "Every day", "Weekdays" or "Mon, Wed, Fri".
    var reminderDaysSummary: String {
        if reminderDays == Set(Weekday.allCases) { return "Every day" }
        if reminderDays == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays" }
        if reminderDays == [.saturday, .sunday] { return "Weekends" }
        if reminderDays.isEmpty { return "No days" }
        return Weekday.allCases.filter { reminderDays.contains($0) }.map(\.shortLabel).joined(separator: ", ")
    }

    /// Suggested activities in stable display order (sets iterate unpredictably).
    var orderedSuggestedActivities: [SuggestedActivity] {
        SuggestedActivity.allCases.filter { suggestedActivities.contains($0) }
    }

    /// Motivational emojis the user can pick to personalize the app.
    static let avatarOptions = ["🏃", "🚶", "🔥", "💪", "🌟", "🧘", "🚴", "⛰️", "❤️", "⚡️"]
}

// MARK: - Reminder days & suggested micro-activities

/// Days of the week the daily reminder may be active.
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }
}

/// Small activities the user is happy to do. Optional during onboarding —
/// used later to suggest easy wins when they're behind on their goal.
enum SuggestedActivity: String, Codable, CaseIterable, Identifiable {
    case shortWalk = "Short walk"
    case takeStairs = "Take the stairs"
    case refillWater = "Refill water"
    case standingCall = "Standing call"
    case stretchBreak = "Stretch break"
    case walkToColleague = "Walk to a colleague"

    var id: String { rawValue }
    var title: String { rawValue }

    /// What picking it means for your fitness — shown under each option.
    var explanation: String {
        switch self {
        case .shortWalk:
            "A 5–10 minute brisk walk. Cardio snacks that add up fast."
        case .takeStairs:
            "A quick climb instead of the elevator. Heart-pumping cardio that builds leg strength."
        case .refillWater:
            "Every refill is a walk to the kitchen — hydration and steps in one habit."
        case .standingCall:
            "Stand and sway while you talk. Burns more energy than sitting and eases a stiff back and hips."
        case .stretchBreak:
            "Two minutes to stretch. Resets posture, eases muscle tension and boosts mobility."
        case .walkToColleague:
            "Skip the chat ping and stroll over. Easy extra steps plus real face time."
        }
    }

    var symbolName: String {
        switch self {
        case .shortWalk: "figure.walk"
        case .takeStairs: "figure.stairs"
        case .refillWater: "drop.fill"
        case .standingCall: "phone.fill"
        case .stretchBreak: "figure.flexibility"
        case .walkToColleague: "person.2.fill"
        }
    }
}

/// Age-based daily step guidance, summarized from:
/// - getsteps.app "Steps Per Day Goal by Age: 2026 Recommended Daily Steps"
/// - Healthline "How Many Steps Do People Take Per Day on Average?"
/// Used to personalize the step-goal screen to the age the user entered.
struct AgeGuidance {
    let bandLabel: String        // e.g. "18–39"
    let recommendedLow: Int      // e.g. 8_000
    let recommendedHigh: Int     // e.g. 10_000
    let distanceTimeNote: String // e.g. "≈3.5–4.5 miles · ~70–90 min"
    let averageNote: String      // typical steps/day for this age group
    let midpoint: Int            // midpoint of the recommended range
}

enum StepGuidance {
    /// Recommended daily steps by age group (getsteps.app, 2026 chart).
    static func age(_ age: Int) -> AgeGuidance {
        switch age {
        case ..<13:
            return AgeGuidance(
                bandLabel: "6–12",
                recommendedLow: 12_000,
                recommendedHigh: 16_000,
                distanceTimeNote: "≈5–7 miles · natural play",
                averageNote: "Kids average 10,000–16,000 steps a day — boys typically more than girls.",
                midpoint: 14_000
            )
        case 13...17:
            return AgeGuidance(
                bandLabel: "13–17",
                recommendedLow: 10_000,
                recommendedHigh: 14_000,
                distanceTimeNote: "≈4.5–6.5 miles · ~90–120 min",
                averageNote: "Teens average just 6,000–8,000 steps a day — well below their target.",
                midpoint: 12_000
            )
        case 18...39:
            return AgeGuidance(
                bandLabel: "18–39",
                recommendedLow: 8_000,
                recommendedHigh: 10_000,
                distanceTimeNote: "≈3.5–4.5 miles · ~70–90 min",
                averageNote: age <= 29
                    ? "People 18–29 average ~7,800 steps a day — slightly short of the target."
                    : "People 30–39 average ~7,000 steps a day — moderately short of the target.",
                midpoint: 9_000
            )
        case 40...59:
            return AgeGuidance(
                bandLabel: "40–59",
                recommendedLow: 7_000,
                recommendedHigh: 10_000,
                distanceTimeNote: "≈3–4.5 miles · ~60–90 min",
                averageNote: age <= 49
                    ? "People 40–49 average ~6,500 steps a day — moderately short of the target."
                    : "People 50–59 average ~5,800 steps a day — well short of the target.",
                midpoint: 8_500
            )
        case 60...69:
            return AgeGuidance(
                bandLabel: "60–69",
                recommendedLow: 6_000,
                recommendedHigh: 8_000,
                distanceTimeNote: "≈2.5–3.5 miles · ~50–70 min",
                averageNote: "People 60–69 average ~5,000 steps a day — just short of the target.",
                midpoint: 7_000
            )
        default:
            return AgeGuidance(
                bandLabel: "70+",
                recommendedLow: 4_500,
                recommendedHigh: 7_000,
                distanceTimeNote: "≈2–3 miles · ~40–60 min",
                averageNote: "People 70+ average ~3,500 steps a day — far short of the target.",
                midpoint: 5_750
            )
        }
    }

    /// Single recommendation used everywhere in the UI: the age-based range from
    /// getsteps.app, positioned by the activity level entered earlier.
    /// Sedentary → low end · Lightly active → quarter point · Moderately active → midpoint · Very active → high end.
    /// Rounded to 250 (the goal slider's step).
    static func recommendedGoal(for age: Int, activityLevel: ActivityLevel) -> Int {
        let guidance = Self.age(age)
        let fraction: Double
        switch activityLevel {
        case .sedentary: fraction = 0
        case .lightlyActive: fraction = 0.25
        case .moderatelyActive: fraction = 0.5
        case .veryActive: fraction = 1
        }
        let raw = Double(guidance.recommendedLow)
            + Double(guidance.recommendedHigh - guidance.recommendedLow) * fraction
        return Int((raw / 250).rounded() * 250)
    }

    /// Rough calorie burn for a daily goal, scaled by body weight.
    /// Derived from getsteps.app: 8,000–10,000 steps ≈ 300–400 calories (~0.04 kcal/step at 70 kg).
    static func estimatedCaloriesPerDay(stepGoal: Int, weightKg: Double) -> Int {
        let scaled = Double(stepGoal) * 0.0375 * (weightKg / 70)
        return Int((scaled / 10).rounded() * 10)
    }
}

/// Reads/writes the onboarding profile to UserDefaults.
enum OnboardingPersistence {
    /// AppStorage key used by the app to decide whether onboarding is complete.
    static let completedKey = "hasCompletedOnboarding"
    private static let profileKey = "onboardingProfile"

    static func save(_ profile: OnboardingProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: profileKey)
        } catch {
            // Non-fatal: the app still works, the profile just won't be restored.
            assertionFailure("Failed to encode onboarding profile: \(error)")
        }
    }

    static func load() -> OnboardingProfile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else { return nil }
        return try? JSONDecoder().decode(OnboardingProfile.self, from: data)
    }
}
