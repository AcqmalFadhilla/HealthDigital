//
//  StepData.swift
//  HealthDigital
//

import Foundation

/// Steps counted within one clock hour of a day.
struct HourlySteps: Identifiable, Equatable {
    let hour: Int
    let steps: Int
    var id: Int { hour }
}

/// One past day, with its cumulative total at the end of each hour (24 values).
struct DayHistory: Identifiable, Equatable {
    let date: Date
    let cumulativeByHour: [Int]
    var id: Date { date }
    var total: Int { cumulativeByHour.last ?? 0 }

    func cumulative(atEndOf hour: Int) -> Int {
        cumulativeByHour[min(max(hour, 0), 23)]
    }
}

/// Everything the hub needs from the step source at one moment.
struct StepSnapshot: Equatable {
    /// Today, per hour, only hours that have started.
    var today: [HourlySteps] = []
    /// Previous days, oldest first. Today is not included.
    var history: [DayHistory] = []
    var lastSync: Date?

    static let empty = StepSnapshot()

    var todayTotal: Int { today.reduce(0) { $0 + $1.steps } }
    var hasData: Bool { lastSync != nil && (todayTotal > 0 || !history.isEmpty) }

    /// Cumulative steps at the end of each hour that has started today.
    var todayCumulative: [HourlySteps] {
        var running = 0
        return today.map { running += $0.steps; return HourlySteps(hour: $0.hour, steps: running) }
    }
}

enum ChartRange: String, CaseIterable, Identifiable {
    case day = "Day", week = "Week"
    var id: Self { self }
}
