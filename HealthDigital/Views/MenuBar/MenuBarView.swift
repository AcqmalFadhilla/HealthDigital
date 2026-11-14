//
//  MenuBarView.swift
//  HealthDigital
//
//  The menu bar extra: today's progress and the daily activity flow
//  (reminder → "Yes, I'm doing it now" → Done).
//

import SwiftUI

struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: model.needsAttention ? "bell.badge.fill" : (model.session.phase == .inProgress ? "figure.walk.motion" : "figure.walk"))
            Text(model.currentSteps.grouped).monospacedDigit()
        }
    }
}

struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            progressHeader
            Divider()
            if model.hasOnboarded {
                activitySection
            } else {
                Text("Finish setting up Step Hub to get your daily activity.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Button("Open Step Hub…") {
                    openWindow(id: "main")
                    NSApp.activate()
                }
                SettingsLink { Text("Settings…") }
                Button("Quit Step Hub") { NSApp.terminate(nil) }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 320)
        .task { await model.refresh() }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Steps today").font(.caption.weight(.semibold)).foregroundStyle(.orange)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(model.currentSteps.grouped).font(.title.bold()).monospacedDigit()
                    .contentTransition(.numericText())
                Text("/ \(model.profile.dailyGoal.grouped)").foregroundStyle(.secondary)
            }
            ProgressView(value: model.progress).tint(.orange)
            Text(model.gap == 0 ? "Goal reached — nice." : "\(model.gap.grouped) to go")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var activitySection: some View {
        let activity = model.todayActivity
        switch model.session.phase {
        case .waiting:
            Label(model.reminderStatusText, systemImage: "bell")
                .font(.callout).foregroundStyle(.secondary)

        case .notified:
            VStack(alignment: .leading, spacing: 10) {
                Text("\(model.profile.reminder.timeLabel) · Time to move").font(.caption.weight(.semibold)).foregroundStyle(.orange)
                HStack(spacing: 12) {
                    Image(systemName: activity?.symbol ?? "figure.stand")
                        .font(.title2).foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.orange))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity?.prompt ?? "Stand up and stretch").font(.headline)
                        Text("\(activity?.estimateLabel ?? "") · \(model.gap.grouped) left today")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Button {
                    model.startActivity()
                } label: {
                    Text("Yes, I’m doing it now").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                HStack {
                    Button("Different activity") { model.swapActivity() }
                        .disabled(model.profile.activities.count < 2)
                    Spacer()
                    Button("Not now") { dismiss() }
                }
                .buttonStyle(.link)
                .font(.caption)
            }

        case .inProgress:
            VStack(alignment: .leading, spacing: 10) {
                Text("In progress · started \(model.session.startedAt.map { Clock.label($0) } ?? "")")
                    .font(.caption.weight(.semibold)).foregroundStyle(.blue)
                Text(activity?.title ?? "Activity").font(.headline)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("+\(model.activitySteps.grouped)").font(.title2.bold()).contentTransition(.numericText())
                    Text("steps so far").font(.caption).foregroundStyle(.secondary)
                }
                Label("Counting from your Watch. Tap Done when you finish.", systemImage: "applewatch")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    model.finishActivity()
                } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button("Cancel") { model.cancelActivity() }
                    .buttonStyle(.link).font(.caption)
            }

        case .completed:
            VStack(alignment: .leading, spacing: 8) {
                Label("Nice work", systemImage: "checkmark.circle.fill")
                    .font(.headline).foregroundStyle(.green)
                Text("\(activity?.title ?? "Today’s activity") added **+\(model.session.creditedSteps.grouped) steps**.")
                    .font(.callout)
                Text("Step Hub is updated. See you tomorrow at \(model.profile.reminder.timeLabel).")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
