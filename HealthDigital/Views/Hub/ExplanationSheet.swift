//
//  ExplanationSheet.swift
//  HealthDigital
//
//  "Why am I seeing this?" — what the insight is based on, the checks it passed, and who wrote it.
//

import SwiftUI

struct ExplanationSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let insight: Insight
    let facts: InsightFacts

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why am I seeing this?").font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Label(insight.source == .onDeviceModel ? "Summary · generated on this Mac" : "Summary · template", systemImage: insight.source == .onDeviceModel ? "sparkles" : "text.alignleft")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(insight.title).font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(insight.body).font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))

            GroupBox("Based on") {
                VStack(alignment: .leading, spacing: 6) {
                    row("Steps today", "\(model.snapshot.today.count) hours synced")
                    row("Past days", facts.historyDays == 0 ? "None yet" : "\(facts.historyDays) days")
                    if facts.phase == .inProgress || facts.phase == .completed {
                        row("Activity check-in", facts.activityStart.map { "Started \($0)" } ?? "—")
                    }
                    row("Source", model.dataSource.displayName)
                    if let sync = model.snapshot.lastSync { row("Last sync", Clock.label(sync)) }
                }
                .padding(4)
            }

            DisclosureGroup("Numbers used") {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(facts.factLines, id: \.self) { Text($0).font(.caption.monospacedDigit()) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }

            GroupBox("Checks") {
                VStack(alignment: .leading, spacing: 6) {
                    check(insight.numbersVerified, "Every number matches your data")
                    check(insight.noMedicalAdvice, "No diagnosis or medical advice")
                }
                .padding(4)
            }

            Text(footer).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                SettingsLink { Text("Privacy Settings…") }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private var footer: String {
        switch insight.source {
        case .onDeviceModel:
            "Written by Apple’s on-device model from the numbers above. Nothing leaves this Mac. Insights are not medical advice."
        case .template(let reason):
            "\(reason.isEmpty ? "Written from a template." : reason + ". Written from a template.") The numbers are the same either way. Insights are not medical advice."
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .font(.callout)
    }

    private func check(_ ok: Bool, _ text: String) -> some View {
        Label(text, systemImage: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(ok ? .green : .red)
            .font(.callout)
    }
}
