//
//  StepDataSource.swift
//  HealthDigital
//
//  The seam between the app and wherever steps come from.
//  The Watch integration (owned by another engineer) should provide a type that conforms to
//  `StepDataSource` and call `onUpdate` whenever new steps sync. Until then the app runs on
//  `SampleStepDataSource`.
//

import Foundation

@MainActor
protocol StepDataSource: AnyObject {
    /// Shown in the explanation sheet ("Based on: …").
    var displayName: String { get }
    /// Call this whenever new step data arrives so the hub, menu bar and insight refresh.
    var onUpdate: (() -> Void)? { get set }

    /// Today's hourly steps plus past days, as of `now`.
    func snapshot(now: Date) async -> StepSnapshot
    /// Steps counted between two moments. Used to credit steps to the daily activity.
    func steps(from start: Date, to end: Date) async -> Int
}

// MARK: - Sample data

enum SampleScenario: String, CaseIterable, Identifiable {
    case normal = "Normal — 14 days of history"
    case buildingBaseline = "Building baseline — 3 days of history"
    case noData = "No data — Watch not connected"
    var id: Self { self }

    var historyDays: Int {
        switch self {
        case .normal: 14
        case .buildingBaseline: 3
        case .noData: 0
        }
    }
}

/// Deterministic fake data shaped like an office workday. Also simulates the Watch syncing
/// steps live while an activity is in progress.
@MainActor
final class SampleStepDataSource: StepDataSource {
    let displayName = "Sample data (Watch integration pending)"
    var onUpdate: (() -> Void)?

    var scenario: SampleScenario = .normal {
        didSet { onUpdate?() }
    }

    /// Steps per hour on a typical workday (index = hour of day).
    private let pattern: [Int] = [
        0, 0, 0, 0, 0, 0, 40, 180, 640, 440, 170, 180,
        1_370, 1_530, 630, 520, 480, 700, 900, 600, 300, 120, 40, 0
    ]
    private var liveEvents: [(date: Date, steps: Int)] = []
    private var walkTimer: Timer?
    private let calendar = Calendar.current

    func snapshot(now: Date) async -> StepSnapshot {
        guard scenario != .noData else { return .empty }

        let hourNow = calendar.component(.hour, from: now)
        let minuteFraction = Double(calendar.component(.minute, from: now)) / 60
        let startOfDay = calendar.startOfDay(for: now)

        var today: [HourlySteps] = []
        for hour in 0...hourNow {
            let base = hour < hourNow ? pattern[hour] : Int(Double(pattern[hour]) * minuteFraction)
            let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay
            let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? hourStart
            let live = liveEvents.filter { $0.date >= hourStart && $0.date < hourEnd }.reduce(0) { $0 + $1.steps }
            today.append(HourlySteps(hour: hour, steps: base + live))
        }

        var history: [DayHistory] = []
        for back in stride(from: scenario.historyDays, through: 1, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -back, to: startOfDay) else { continue }
            let weekend = calendar.isDateInWeekend(date)
            let factor = (weekend ? 1.15 : 1.0) * Self.noise(for: date, calendar: calendar)
            var running = 0
            let cumulative = pattern.map { running += Int(Double($0) * factor); return running }
            history.append(DayHistory(date: date, cumulativeByHour: cumulative))
        }

        return StepSnapshot(today: today, history: history, lastSync: now)
    }

    func steps(from start: Date, to end: Date) async -> Int {
        liveEvents.filter { $0.date >= start && $0.date <= end }.reduce(0) { $0 + $1.steps }
    }

    /// Pretend the user is walking: the "Watch" syncs a few dozen steps every couple of seconds.
    func setSimulatedWalking(_ walking: Bool) {
        walkTimer?.invalidate()
        walkTimer = nil
        guard walking else { return }
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.liveEvents.append((Date(), Int.random(in: 32...46)))
                self.onUpdate?()
            }
        }
    }

    /// Stable pseudo-random factor between 0.7 and 1.3 per date.
    private static func noise(for date: Date, calendar: Calendar) -> Double {
        let day = Double(calendar.ordinality(of: .day, in: .era, for: date) ?? 0)
        let x = sin(day * 12.9898) * 43_758.5453
        return 0.7 + (x - floor(x)) * 0.6
    }
}
