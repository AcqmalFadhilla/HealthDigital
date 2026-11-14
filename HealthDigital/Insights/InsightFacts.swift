//
//  InsightFacts.swift
//  HealthDigital
//
//  Every number an insight is allowed to mention, computed in code from the user's data.
//  The language model only turns these facts into words; it never does the math.
//

import Foundation

struct InsightFacts: Equatable {
    enum Phase: String { case waiting, notified, inProgress, completed }

    static let baselineDaysNeeded = 7

    var now: Date
    var range: ChartRange
    var phase: Phase
    var hasData: Bool

    var goal: Int
    var current: Int
    var gap: Int { max(goal - current, 0) }
    var percent: Int { goal > 0 ? min(100, Int((Double(current) / Double(goal) * 100).rounded())) : 0 }

    /// Days of history available; insights that compare to "usual" need `baselineDaysNeeded`.
    var historyDays: Int
    var hasBaseline: Bool { historyDays >= Self.baselineDaysNeeded }
    /// Average steps by this time of day over past days.
    var usualByNow: Int?
    /// Two-hour window with the most steps today, e.g. "12:00–14:00".
    var busiestWindow: String?
    /// If the usual rest-of-day pace gets the user to goal: around when.
    var projectedGoalTime: String?
    /// If not: how many steps short at the end of a usual day.
    var projectedShortfall: Int?

    var activityTitle: String?
    var activityEstimate: Int?
    var activityStart: String?
    var activitySteps: Int

    var weekGoalDays: Int?
    var weekDaysCounted: Int
    var weekAverage: Int?

    var motivations: [String]

    // MARK: Derived

    /// Changes only when the *kind* of message should change, so the model isn't re-run on every sync.
    var regenerationKey: String {
        let quarter = Calendar.current.component(.hour, from: now) * 4 + Calendar.current.component(.minute, from: now) / 15
        return [range.rawValue, phase.rawValue, "\(gap == 0)", "\(hasBaseline)", "\(hasData)", "\(activityTitle ?? "")", phase == .inProgress ? "" : "\(quarter)"].joined(separator: "|")
    }

    var nowLabel: String { Clock.label(now) }

    /// Numbers the text may contain. Anything else fails the "every number matches your data" check.
    var allowedNumbers: Set<Int> {
        var set: Set<Int> = [goal, current, gap, percent, historyDays, activitySteps, weekDaysCounted]
        [usualByNow, projectedShortfall, activityEstimate, weekGoalDays, weekAverage].compactMap { $0 }.forEach { set.insert($0) }
        if let usual = usualByNow { set.insert(abs(current - usual)) }
        set.insert(Self.baselineDaysNeeded)
        return set
    }

    var allowedTimes: Set<String> {
        var set: Set<String> = [nowLabel]
        [projectedGoalTime, activityStart].compactMap { $0 }.forEach { set.insert($0) }
        if let window = busiestWindow { window.split(separator: "–").forEach { set.insert(String($0)) } }
        return set
    }

    /// Plain-language fact list: fed to the model and shown in "Why am I seeing this?".
    var factLines: [String] {
        var lines = [
            "View: \(range == .day ? "today" : "this week")",
            "Time now: \(nowLabel)",
            "Steps so far today: \(current.grouped)",
            "Daily goal: \(goal.grouped)",
            "Steps left to goal: \(gap.grouped)",
            "Percent of goal: \(percent)%"
        ]
        if let usual = usualByNow {
            let diff = current - usual
            lines.append("Usual steps by this time (\(historyDays)-day average): \(usual.grouped)")
            lines.append(diff >= 0 ? "Ahead of usual by: \(diff.grouped)" : "Behind usual by: \(abs(diff).grouped)")
        }
        if let window = busiestWindow { lines.append("Busiest window today: \(window)") }
        if let time = projectedGoalTime { lines.append("At the usual pace, goal is reached around: \(time)") }
        if let short = projectedShortfall { lines.append("At the usual pace, the day ends short by: \(short.grouped)") }
        switch phase {
        case .waiting: lines.append("Daily activity: not yet")
        case .notified: lines.append("Daily activity suggested now: \(activityTitle ?? "—"), about \(activityEstimate?.grouped ?? "—") steps")
        case .inProgress: lines.append("Daily activity in progress: \(activityTitle ?? "—"), started \(activityStart ?? "—"), \(activitySteps.grouped) steps so far")
        case .completed: lines.append("Daily activity done: \(activityTitle ?? "—"), added \(activitySteps.grouped) steps")
        }
        if range == .week {
            if let days = weekGoalDays { lines.append("Days that reached the goal: \(days) of the last \(weekDaysCounted)") }
            if let avg = weekAverage { lines.append("Average daily steps, last \(weekDaysCounted) days: \(avg.grouped)") }
        }
        if !motivations.isEmpty { lines.append("What motivates the user: \(motivations.joined(separator: ", "))") }
        return lines
    }
}

extension InsightFacts {
    static func make(snapshot: StepSnapshot,
                     profile: OnboardingProfile,
                     session: ActivitySession,
                     activity: SuggestedActivity?,
                     activitySteps: Int,
                     range: ChartRange,
                     now: Date,
                     calendar: Calendar = .current) -> InsightFacts {
        let current = snapshot.todayTotal
        let hour = calendar.component(.hour, from: now)
        let fraction = Double(calendar.component(.minute, from: now)) / 60
        let history = snapshot.history

        // Usual by now, and usual rest-of-day pace.
        var usualByNow: Int?
        var projectedGoalTime: String?
        var projectedShortfall: Int?
        if history.count >= baselineDaysNeeded {
            func usualAt(_ day: DayHistory) -> Double {
                let before = hour > 0 ? Double(day.cumulative(atEndOf: hour - 1)) : 0
                let inHour = Double(day.cumulative(atEndOf: hour)) - before
                return before + inHour * fraction
            }
            let nowAvg = history.map(usualAt).reduce(0, +) / Double(history.count)
            usualByNow = Int(nowAvg.rounded(toNearest: 10))

            let remainingAvg = history.map { Double($0.total) - usualAt($0) }.reduce(0, +) / Double(history.count)
            if Double(current) + remainingAvg >= Double(profile.dailyGoal) && current < profile.dailyGoal {
                // First hour where current + usual progress since now crosses goal.
                for h in hour..<24 {
                    let avgCum = history.map { Double($0.cumulative(atEndOf: h)) }.reduce(0, +) / Double(history.count)
                    let prevCum = h > 0 ? history.map { Double($0.cumulative(atEndOf: h - 1)) }.reduce(0, +) / Double(history.count) : 0
                    let projected = Double(current) + avgCum - nowAvg
                    if projected >= Double(profile.dailyGoal) {
                        let need = Double(profile.dailyGoal) - (Double(current) + prevCum - nowAvg)
                        let inHour = max(avgCum - prevCum, 1)
                        let minute = Int((min(max(need / inHour, 0), 1) * 60 / 15).rounded()) * 15
                        projectedGoalTime = Clock.label(minutes: (h * 60 + minute))
                        break
                    }
                }
            } else if current < profile.dailyGoal {
                projectedShortfall = Int((Double(profile.dailyGoal) - Double(current) - remainingAvg).rounded(toNearest: 10))
            }
        }

        // Busiest two-hour window today.
        var busiest: String?
        let hours = snapshot.today
        if hours.count >= 2 {
            var best = (start: 0, steps: -1)
            for i in 0..<(hours.count - 1) {
                let s = hours[i].steps + hours[i + 1].steps
                if s > best.steps { best = (hours[i].hour, s) }
            }
            if best.steps > 0 { busiest = "\(Clock.label(minutes: best.start * 60))–\(Clock.label(minutes: (best.start + 2) * 60))" }
        }

        // Week (last 6 full days).
        let lastWeek = Array(history.suffix(6))
        let weekGoalDays = lastWeek.isEmpty ? nil : lastWeek.filter { $0.total >= profile.dailyGoal }.count
        let weekAverage = lastWeek.isEmpty ? nil : Int((Double(lastWeek.map(\.total).reduce(0, +)) / Double(lastWeek.count)).rounded(toNearest: 10))

        let phase: Phase = switch session.phase {
        case .waiting: .waiting
        case .notified: .notified
        case .inProgress: .inProgress
        case .completed: .completed
        }

        return InsightFacts(
            now: now, range: range, phase: phase, hasData: snapshot.hasData,
            goal: profile.dailyGoal, current: current,
            historyDays: history.count, usualByNow: usualByNow, busiestWindow: busiest,
            projectedGoalTime: projectedGoalTime, projectedShortfall: projectedShortfall,
            activityTitle: activity?.title, activityEstimate: activity?.estimatedSteps,
            activityStart: session.startedAt.map { Clock.label($0) }, activitySteps: activitySteps,
            weekGoalDays: weekGoalDays, weekDaysCounted: lastWeek.count, weekAverage: weekAverage,
            motivations: profile.orderedMotivations.map(\.title)
        )
    }
}

private extension Double {
    func rounded(toNearest step: Double) -> Double { (self / step).rounded() * step }
}
