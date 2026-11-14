//
//  StepActivity.swift
//  HealthDigital
//

import Foundation

/// Activities a user can opt into. The daily reminder suggests exactly one of the picked ones.
enum StepActivity: String, Codable, CaseIterable, Identifiable {
    case shortWalk, takeStairs, refillWater, standingCall, stretchBreak, walkToColleague
    var id: Self { self }

    var title: String {
        switch self {
        case .shortWalk: "Short walk"
        case .takeStairs: "Take the stairs"
        case .refillWater: "Refill water"
        case .standingCall: "Standing call"
        case .stretchBreak: "Stretch break"
        case .walkToColleague: "Walk to a colleague"
        }
    }

    var prompt: String {
        switch self {
        case .shortWalk: "Take a 15-minute walk, outdoors or around the office"
        case .takeStairs: "Take the stairs up and down a few floors"
        case .refillWater: "Refill your water on another floor"
        case .standingCall: "Take your next call standing and pacing"
        case .stretchBreak: "Stand up for a 5-minute stretch"
        case .walkToColleague: "Walk over to a colleague instead of messaging"
        }
    }

    var minutes: Int {
        switch self {
        case .shortWalk: 15
        case .takeStairs: 5
        case .refillWater: 4
        case .standingCall: 10
        case .stretchBreak: 5
        case .walkToColleague: 5
        }
    }

    /// Rough expected steps, only used for the suggestion text. Real credit comes from the Watch.
    var estimatedSteps: Int {
        switch self {
        case .shortWalk: 1_600
        case .takeStairs: 400
        case .refillWater: 300
        case .standingCall: 1_000
        case .stretchBreak: 100
        case .walkToColleague: 250
        }
    }

    var estimateLabel: String { "≈ \(estimatedSteps.grouped) steps" }

    var symbol: String {
        switch self {
        case .shortWalk: "figure.walk"
        case .takeStairs: "figure.stairs"
        case .refillWater: "waterbottle"
        case .standingCall: "phone.fill"
        case .stretchBreak: "figure.flexibility"
        case .walkToColleague: "person.2.fill"
        }
    }

    /// Picks today's activity from the user's set. Rotates by day; `offset` comes from "Different activity".
    static func activity(for date: Date, from picks: Set<StepActivity>, offset: Int = 0, calendar: Calendar = .current) -> StepActivity? {
        let ordered = allCases.filter(picks.contains)
        guard !ordered.isEmpty else { return nil }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return ordered[(day + offset) % ordered.count]
    }
}
