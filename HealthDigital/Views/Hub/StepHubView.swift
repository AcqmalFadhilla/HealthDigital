//
//  StepHubView.swift
//  HealthDigital
//

import SwiftUI

struct StepHubView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .bottom) {
                    StepsHero()
                    Spacer()
                    Picker("Range", selection: $model.range) {
                        ForEach(ChartRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 160)
                }

                if model.facts?.hasData ?? false {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.range == .day ? "Cumulative steps by hour" : "Daily total · last 7 days")
                            .font(.caption).foregroundStyle(.secondary)
                        StepsChart().frame(height: 240)
                        if model.range == .day, (model.facts?.hasBaseline ?? false) {
                            Label("Grey band: your usual range by this hour, from the last \(model.facts?.historyDays ?? 0) days", systemImage: "square.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                InsightCard()

                if model.profile.reminder.isEnabled || model.session.phase != .waiting {
                    TodayActivityCard()
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .navigationTitle("Step Hub")
        .navigationSubtitle(model.now.formatted(date: .complete, time: .omitted))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(model.reminderStatusText)
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(statusColor.opacity(0.14)))
                    .foregroundStyle(statusColor)
            }
        }
    }

    private var statusColor: Color {
        switch model.session.phase {
        case .waiting: .secondary
        case .notified: .orange
        case .inProgress: .blue
        case .completed: .green
        }
    }
}

/// Current steps vs goal, the gap, and the evidence ("the number and the usual").
struct StepsHero: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Steps", systemImage: "figure.walk")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.orange)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(model.currentSteps.grouped)
                    .font(.system(size: 46, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("/ \(model.profile.dailyGoal.grouped) steps")
                    .font(.title3.weight(.medium)).foregroundStyle(.secondary)
                if model.activitySteps > 0 {
                    Text(model.session.phase == .completed ? "+\(model.activitySteps.grouped) just now" : "+\(model.activitySteps.grouped) live")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(model.session.phase == .completed ? Color.green.opacity(0.15) : Color.blue.opacity(0.12)))
                        .foregroundStyle(model.session.phase == .completed ? .green : .blue)
                }
            }
            .animation(.snappy, value: model.currentSteps)

            HStack(spacing: 10) {
                ProgressView(value: model.progress)
                    .tint(.orange)
                    .frame(width: 320)
                Text(model.gap == 0 ? "Goal reached" : "\(model.gap.grouped) to go").font(.callout.weight(.semibold))
                Text("\(Int((model.progress * 100).rounded()))%").font(.callout).foregroundStyle(.secondary)
            }

            if let facts = model.facts, facts.hasData {
                Group {
                    if let usual = facts.usualByNow {
                        let diff = facts.current - usual
                        let comparison = Text(diff >= 0 ? "\(diff.grouped) ahead" : "\(abs(diff).grouped) behind").bold()
                        Text("Usual by \(facts.nowLabel): \(usual.grouped) (\(facts.historyDays)-day average) · \(comparison)")
                    } else {
                        Text("Usual by now: building baseline (\(facts.historyDays) of \(InsightFacts.baselineDaysNeeded) days)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
    }
}
