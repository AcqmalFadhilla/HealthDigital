//
//  TodayActivityCard.swift
//  HealthDigital
//
//  Mirrors the menu bar flow inside the main window.
//

import SwiftUI

struct TodayActivityCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let phase = model.session.phase
        HStack(spacing: 14) {
            Image(systemName: model.todayActivity?.symbol ?? "figure.stand")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 9).fill(.orange.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                Text(model.todayActivity?.prompt ?? "Stand up and stretch for a few minutes").font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()

            switch phase {
            case .waiting:
                EmptyView()
            case .notified:
                Button("Different activity") { model.swapActivity() }
                    .buttonStyle(.borderless)
                    .disabled(model.profile.activities.count < 2)
                Button("Yes, I’m doing it now") { model.startActivity() }
                    .buttonStyle(.borderedProminent)
            case .inProgress:
                VStack(alignment: .trailing, spacing: 0) {
                    Text("+\(model.activitySteps.grouped)").font(.title3.bold()).foregroundStyle(.blue)
                        .contentTransition(.numericText())
                    Text("steps so far").font(.caption2).foregroundStyle(.secondary)
                }
                Button("Done") { model.finishActivity() }
                    .buttonStyle(.borderedProminent)
            case .completed:
                Label("+\(model.session.creditedSteps.grouped)", systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(phase == .inProgress ? Color.blue : Color.secondary.opacity(0.25), lineWidth: phase == .inProgress ? 1.5 : 0.5)
        )
        .animation(.snappy, value: model.activitySteps)
    }

    private var eyebrow: String {
        switch model.session.phase {
        case .waiting: "TODAY’S ACTIVITY · REMINDER AT \(model.profile.reminder.timeLabel)"
        case .notified: "TODAY’S ACTIVITY · READY"
        case .inProgress: "IN PROGRESS · STARTED \(model.session.startedAt.map { Clock.label($0) } ?? "")"
        case .completed: "TODAY’S ACTIVITY · DONE \(model.session.completedAt.map { Clock.label($0) } ?? "")"
        }
    }

    private var detail: String {
        guard let activity = model.todayActivity else { return "Pick activities in Settings to get suggestions" }
        switch model.session.phase {
        case .waiting, .notified: return "\(activity.minutes) min · \(activity.estimateLabel)"
        case .inProgress: return "Counting from your Watch — tap Done when you finish"
        case .completed:
            let next = SuggestedActivity.activity(for: Calendar.current.date(byAdding: .day, value: 1, to: model.now) ?? model.now, from: model.profile.activities)
            return next.map { "Tomorrow: \($0.title)" } ?? ""
        }
    }
}
