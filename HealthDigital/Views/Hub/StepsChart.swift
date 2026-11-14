//
//  StepsChart.swift
//  HealthDigital
//
//  Day: cumulative steps per hour. Week: daily totals.
//  Goal = thin grey rule with a "Goal 8,000" label (option A).
//  The current bar shows the activity's steps in a darker segment and the gap to goal as a light block.
//

import SwiftUI
import Charts

struct StepsChart: View {
    @Environment(AppModel.self) private var model

    private struct Segment: Identifiable {
        enum Kind { case steps, underGoal, activity, gap }
        let id = UUID()
        let x: String
        let from: Int
        let to: Int
        let kind: Kind
    }

    var body: some View {
        let goal = model.profile.dailyGoal
        let (segments, domain) = model.range == .day ? daySegments() : weekSegments()
        let top = max(Double(goal) * 1.15, Double(segments.map(\.to).max() ?? 0) * 1.1)

        Chart {
            if model.range == .day {
                ForEach(usualBand(domain: domain), id: \.x) { band in
                    AreaMark(x: .value("Time", band.x),
                             yStart: .value("Usual low", band.low),
                             yEnd: .value("Usual high", band.high))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.secondary.opacity(0.14))
                }
            }
            ForEach(segments) { seg in
                BarMark(x: .value("Time", seg.x),
                        yStart: .value("From", seg.from),
                        yEnd: .value("Steps", seg.to),
                        width: .ratio(0.7))
                    .foregroundStyle(color(for: seg.kind))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: seg.kind == .steps && hasSegmentAbove(seg, in: segments) ? 0 : 4,
                                                      topTrailingRadius: seg.kind == .steps && hasSegmentAbove(seg, in: segments) ? 0 : 4))
                    .annotation(position: .top, spacing: 6) {
                        if seg.kind == .gap {
                            Text("\((seg.to - seg.from).grouped) to go")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Capsule().fill(Color.primary))
                                .fixedSize()
                        }
                    }
            }
            RuleMark(y: .value("Goal", goal))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .annotation(position: .top, alignment: .leading, spacing: 2) {
                    Text("Goal \(goal.grouped)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
        }
        .chartXScale(domain: domain)
        .chartYScale(domain: 0...top)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                AxisValueLabel { if let v = value.as(Int.self) { Text(v.grouped) } }
            }
        }
        .chartLegend(.hidden)
        .animation(.easeInOut(duration: 0.5), value: model.currentSteps)
        .accessibilityLabel(model.range == .day ? "Cumulative steps by hour" : "Daily steps this week")
        .accessibilityValue("\(model.currentSteps.grouped) of \(goal.grouped) steps")
    }

    /// "The usual": middle half (25th–75th percentile) of past days' cumulative steps at each hour.
    /// Only drawn once there's a baseline.
    private func usualBand(domain: [String]) -> [(x: String, low: Int, high: Int)] {
        let history = model.snapshot.history
        guard history.count >= InsightFacts.baselineDaysNeeded else { return [] }
        return domain.compactMap { label in
            guard let hour = Int(label) else { return nil }
            let values = history.map { $0.cumulative(atEndOf: hour) }.sorted()
            let low = values[values.count / 4]
            let high = values[(values.count * 3) / 4]
            return (label, low, high)
        }
    }

    private func hasSegmentAbove(_ seg: Segment, in all: [Segment]) -> Bool {
        all.contains { $0.x == seg.x && $0.from == seg.to && $0.kind == .activity }
    }

    private func color(for kind: Segment.Kind) -> Color {
        switch kind {
        case .steps: .orange
        case .underGoal: .orange.opacity(0.45)
        case .activity: Color(red: 0.72, green: 0.33, blue: 0.0)
        case .gap: .orange.opacity(0.16)
        }
    }

    /// Segments for the current bar: base steps, activity steps, gap to goal.
    private func currentBar(x: String, total: Int) -> [Segment] {
        let goal = model.profile.dailyGoal
        let activity = min(model.activitySteps, total)
        var result = [Segment(x: x, from: 0, to: total - activity, kind: .steps)]
        if activity > 0 { result.append(Segment(x: x, from: total - activity, to: total, kind: .activity)) }
        if total < goal { result.append(Segment(x: x, from: total, to: goal, kind: .gap)) }
        return result
    }

    private func daySegments() -> ([Segment], [String]) {
        let cumulative = model.snapshot.todayCumulative
        let currentHour = Calendar.current.component(.hour, from: model.now)
        let firstHour = min(7, cumulative.first(where: { $0.steps > 0 })?.hour ?? 7)
        let lastHour = max(20, currentHour)
        let domain = (firstHour...lastHour).map { String(format: "%02d", $0) }

        var segments: [Segment] = []
        for point in cumulative where point.hour >= firstHour {
            let x = String(format: "%02d", point.hour)
            if point.hour == currentHour {
                segments += currentBar(x: x, total: point.steps)
            } else if point.steps > 0 {
                segments.append(Segment(x: x, from: 0, to: point.steps, kind: .steps))
            }
        }
        return (segments, domain)
    }

    private func weekSegments() -> ([Segment], [String]) {
        let goal = model.profile.dailyGoal
        let fmt = Date.FormatStyle().weekday(.abbreviated)
        let days = Array(model.snapshot.history.suffix(6))
        var segments: [Segment] = []
        var domain: [String] = []
        for day in days {
            let x = day.date.formatted(fmt)
            domain.append(x)
            segments.append(Segment(x: x, from: 0, to: day.total, kind: day.total >= goal ? .steps : .underGoal))
        }
        domain.append("Today")
        segments += currentBar(x: "Today", total: model.currentSteps)
        return (segments, domain)
    }
}
