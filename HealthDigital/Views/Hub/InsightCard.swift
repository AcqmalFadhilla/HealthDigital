//
//  InsightCard.swift
//  HealthDigital
//
//  The insight under the chart, written by Apple's on-device model (or a template fallback),
//  plus the fallback states: no data, and baseline still building.
//

import SwiftUI

struct InsightCard: View {
    @Environment(AppModel.self) private var model
    @State private var showExplanation = false

    var body: some View {
        if let facts = model.facts, !facts.hasData {
            NoDataCard(reason: model.awaitingWatchConsent ? .awaitingConsent : (model.consent.useStepData ? .noData : .notShared))
        } else if let insight = model.insight, let facts = model.facts {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.source == .onDeviceModel ? "sparkles" : "lightbulb")
                        .font(.title3)
                        .foregroundStyle(facts.phase == .completed ? .green : .orange)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title).font(.headline)
                            .contentTransition(.opacity)
                        Text(insight.body).font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentTransition(.opacity)
                    }
                    Spacer(minLength: 0)
                }

                if !facts.hasBaseline {
                    BaselineProgress(days: facts.historyDays)
                }

                HStack(spacing: 6) {
                    if model.isWritingInsight {
                        ProgressView().controlSize(.mini)
                        Text("Writing with Apple Intelligence…")
                    } else {
                        Text(sourceLabel(insight))
                    }
                    Text("·")
                    Text(facts.phase == .inProgress ? "Live · updated \(facts.nowLabel)" : "Updated \(facts.nowLabel)")
                    Spacer()
                    Button("Why am I seeing this?") { showExplanation = true }
                        .buttonStyle(.link)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(background(for: facts.phase)))
            .animation(.easeInOut, value: insight)
            .sheet(isPresented: $showExplanation) {
                ExplanationSheet(insight: insight, facts: facts)
                    .environment(model)
            }
        }
    }

    private func sourceLabel(_ insight: Insight) -> String {
        switch insight.source {
        case .onDeviceModel: "Written on this Mac by Apple Intelligence"
        case .template(let reason): reason.isEmpty ? "Template insight" : "Template insight — \(reason)"
        }
    }

    private func background(for phase: InsightFacts.Phase) -> Color {
        switch phase {
        case .completed: .green.opacity(0.10)
        case .inProgress: .blue.opacity(0.07)
        default: .secondary.opacity(0.08)
        }
    }
}

/// "Building your baseline": comparisons with your usual start after enough days.
struct BaselineProgress: View {
    let days: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "hourglass")
                Text("Building your baseline").font(.caption.weight(.semibold))
                Spacer()
                Text("\(days) of \(InsightFacts.baselineDaysNeeded) days").font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(days), total: Double(InsightFacts.baselineDaysNeeded))
                .tint(.orange)
            Text("Comparisons with your usual day appear after \(InsightFacts.baselineDaysNeeded) days of steps.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(.background.opacity(0.6)))
    }
}

/// Fallback when there's no step data: consent not given yet, steps not shared, or nothing synced.
struct NoDataCard: View {
    enum Reason { case awaitingConsent, notShared, noData }
    let reason: Reason

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.largeTitle).foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.08)))
    }

    private var symbol: String {
        switch reason {
        case .awaitingConsent: "applewatch.radiowaves.left.and.right"
        case .notShared: "hand.raised"
        case .noData: "applewatch.slash"
        }
    }

    private var title: String {
        switch reason {
        case .awaitingConsent: "Allow Step Hub on your Apple Watch"
        case .notShared: "Steps aren’t shared"
        case .noData: "No step data yet"
        }
    }

    private var message: String {
        switch reason {
        case .awaitingConsent: "Open Step Hub on your Watch to choose what’s shared. Your progress and insights appear here right after."
        case .notShared: "Step count is off. You can turn it on in Step Hub on your Apple Watch."
        case .noData: "Wear your Apple Watch so your steps can sync. No data means no insight — nothing is guessed."
        }
    }
}
