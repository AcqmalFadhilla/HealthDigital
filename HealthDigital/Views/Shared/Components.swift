//
//  Components.swift
//  HealthDigital
//
//  Controls shared by onboarding and Settings so both always offer the same choices.
//

import SwiftUI

// MARK: - Weekday picker ("Active on")

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    /// Monday-first order using Calendar weekday numbers (1 = Sunday).
    private let order = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(order, id: \.self) { day in
                let on = selection.contains(day)
                let name = Calendar.current.weekdaySymbols[day - 1]
                Button {
                    if on { selection.remove(day) } else { selection.insert(day) }
                } label: {
                    Text(String(name.prefix(1)))
                        .font(.caption.weight(.semibold))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(on ? Color.accentColor : Color.secondary.opacity(0.15)))
                        .foregroundStyle(on ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(name)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

// MARK: - Time stepper ("Remind me at")

struct ReminderTimeStepper: View {
    @Binding var minutes: Int
    var step = 15

    var body: some View {
        HStack(spacing: 4) {
            Text(Clock.label(minutes: minutes))
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).strokeBorder(.separator))
            Stepper("Remind me at", value: $minutes, in: 0...(24 * 60 - step), step: step)
                .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Clock.label(minutes: minutes))
    }
}

// MARK: - Goal stepper

struct GoalStepper: View {
    @Binding var goal: Int
    var large = false

    var body: some View {
        HStack(spacing: large ? 20 : 8) {
            Button { goal = max(1_000, goal - 500) } label: { Image(systemName: "minus") }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .accessibilityLabel("Decrease goal")
            VStack(spacing: 0) {
                Text(goal.grouped)
                    .font(large ? .system(size: 46, weight: .bold) : .title3.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if large { Text("steps per day").font(.callout).foregroundStyle(.secondary) }
            }
            .frame(minWidth: large ? 200 : 70)
            Button { goal = min(30_000, goal + 500) } label: { Image(systemName: "plus") }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .accessibilityLabel("Increase goal")
        }
        .animation(.snappy, value: goal)
    }
}

// MARK: - Chips ("What drives you")

struct MotivationChips: View {
    @Binding var selection: Set<Motivation>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Motivation.allCases) { m in
                let on = selection.contains(m)
                Button {
                    if on { selection.remove(m) } else { selection.insert(m) }
                } label: {
                    Text(m.label)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(on ? Color.accentColor.opacity(0.12) : Color.clear))
                        .overlay(Capsule().strokeBorder(on ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: on ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

// MARK: - Activity tiles

struct ActivityTiles: View {
    @Binding var selection: Set<StepActivity>
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(StepActivity.allCases) { a in
                let on = selection.contains(a)
                Button {
                    if on { selection.remove(a) } else { selection.insert(a) }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: a.symbol).font(.title3).foregroundStyle(.orange)
                        Text(a.title).font(.headline)
                        Text("\(a.minutes) min · \(a.estimateLabel)").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(on ? Color.accentColor.opacity(0.08) : Color.clear))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(on ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: on ? 2 : 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

// MARK: - Simple flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for (i, sub) in subviews.enumerated() {
            let size = sub.sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let added = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            rows[rows.count - 1].indices.append(i)
            rows[rows.count - 1].width += added
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}

// MARK: - Consent status (consent itself is given on Apple Watch)

struct WatchConsentStatus: View {
    let consent: ConsentSettings
    var aiUnavailableReason: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !consent.hasReviewed {
                HStack(spacing: 12) {
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .font(.largeTitle).foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Step Hub on your Apple Watch").font(.headline)
                        Text("Review what’s shared, why, and where it stays, then tap Allow. This page updates on its own.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Waiting for your Watch…").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Label("Consent given on \(consent.grantedOn ?? "Apple Watch")", systemImage: "checkmark.seal.fill")
                    .font(.headline).foregroundStyle(.green)
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        row("Step count", consent.useStepData, "figure.walk")
                        row("Activity check-ins", consent.useActivityLog, "checkmark.circle")
                        row("On-device insights", consent.useOnDeviceAI, "sparkles")
                        if consent.useOnDeviceAI, let reason = aiUnavailableReason {
                            Text("\(reason). You’ll see template insights until it’s available.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(4)
                } label: {
                    Text("What’s shared").font(.subheadline.weight(.semibold))
                }
                if let date = consent.grantedAt {
                    Text("Last updated \(date.formatted(date: .abbreviated, time: .shortened)). To change this, open Step Hub on your Apple Watch.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func row(_ title: String, _ on: Bool, _ symbol: String) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(.orange).frame(width: 20)
            Text(title)
            Spacer()
            Text(on ? "On" : "Off").foregroundStyle(on ? .primary : .secondary)
        }
    }
}
