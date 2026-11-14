//
//  OnboardingSteps.swift
//  StepsGoals
//
//  Created by Training-08 on 14/11/26.
//

import SwiftUI

// MARK: - Shared styling

enum OnboardingStyle {
    /// Energetic gradient used for the logo mark and accent elements.
    static let accentGradient = LinearGradient(
        colors: [.orange, .pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Soft background wash so the onboarding doesn't feel like a plain form.
    static let backgroundGradient = LinearGradient(
        colors: [Color.orange.opacity(0.12), Color.pink.opacity(0.05), Color.clear],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// Title + subtitle pair used at the top of each step.
struct OnboardingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Selectable row used for gender and activity level.
struct OnboardingSelectableRow: View {
    let symbolName: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .orange)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? AnyShapeStyle(OnboardingStyle.accentGradient) : AnyShapeStyle(Color.orange.opacity(0.12)), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.orange : Color(nsColor: .quaternaryLabelColor))
            }
            .padding(10)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStep: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
            Spacer(minLength: 8)

            // Logo mark: gradient disc with the app symbol.
            ZStack {
                Circle()
                    .fill(OnboardingStyle.accentGradient)
                    .frame(width: 128, height: 128)
                    .shadow(color: .orange.opacity(0.4), radius: 24, y: 12)

                Image(systemName: "shoeprints.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("StepsGoals")
                    .font(.largeTitle.bold())
                Text("Small steps, big changes.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Quick preview of what the app personalizes for the user.
            VStack(alignment: .leading, spacing: 16) {
                featureRow(symbolName: "target", text: "A daily step goal that fits your life")
                featureRow(symbolName: "bell.badge", text: "Friendly reminders to keep you moving")
                featureRow(symbolName: "flame.fill", text: "Motivation tuned to why you walk")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))

            Text("Answer a few quick questions and we'll tailor everything to you. It takes under a minute.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func featureRow(symbolName: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Step 1: About you

struct AboutYouStep: View {
    @Binding var profile: OnboardingProfile
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                OnboardingHeader(
                    title: "About you",
                    subtitle: "Tell us the basics."
                )

                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Label("Name", systemImage: "person.text.rectangle")
                        .font(.headline)
                    TextField("Your first name", text: $profile.name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .submitLabel(.done)
                        .focused($isNameFocused)
                        .autocorrectionDisabled()
                }

                // Age — stepper + large readout avoids scroll-gesture conflicts.
                VStack(alignment: .leading, spacing: 6) {
                    Label("Age", systemImage: "calendar")
                        .font(.headline)
                    HStack {
                        Stepper(value: $profile.age, in: 10...100) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(profile.age)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                Text("years")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Gender — selectable list (optional, defaults to "prefer not to say").
                VStack(alignment: .leading, spacing: 8) {
                    Label("Gender", systemImage: "person.2")
                        .font(.headline)
                    Text("Optional — used only to tailor insights.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        ForEach(Gender.allCases) { gender in
                            OnboardingSelectableRow(
                                symbolName: gender.symbolName,
                                title: gender.label,
                                isSelected: profile.gender == gender
                            ) {
                                profile.gender = gender
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
    }
}

// MARK: - Step 2: Body & activity

struct BodyMetricsStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingHeader(
                    title: "Your body",
                    subtitle: "Height, weight and activity level — used to estimate calorie burn. Never shared."
                )

                // Height
                MetricSlider(
                    label: "Height",
                    systemImage: "ruler",
                    value: $profile.heightCm,
                    range: 130...210,
                    step: 1,
                    readout: String(format: "%.0f cm", profile.heightCm),
                    secondary: profile.heightImperial
                )

                // Weight
                MetricSlider(
                    label: "Weight",
                    systemImage: "scalemass",
                    value: $profile.weightKg,
                    range: 35...160,
                    step: 0.5,
                    readout: String(format: "%.1f kg", profile.weightKg),
                    secondary: profile.weightImperial
                )

                // Activity level
                VStack(alignment: .leading, spacing: 8) {
                    Label("Activity level", systemImage: "figure.run")
                        .font(.headline)
                    Text("We'll use this to recommend your daily goal.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        ForEach(ActivityLevel.allCases) { level in
                            OnboardingSelectableRow(
                                symbolName: level.symbolName,
                                title: level.title,
                                subtitle: level.subtitle,
                                isSelected: profile.activityLevel == level
                            ) {
                                profile.activityLevel = level
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

/// Reusable slider row with a large readout and secondary (imperial) unit.
private struct MetricSlider: View {
    let label: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let readout: String
    let secondary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: systemImage)
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(readout)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(secondary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
                .tint(.orange)
        }
    }
}

// MARK: - Step 3: Step goal

struct StepGoalStep: View {
    @Binding var profile: OnboardingProfile

    private static let quickPicks = [5_000, 7_500, 10_000, 12_500, 15_000]

    /// Age-based guidance derived from the age the user entered earlier.
    private var guidance: AgeGuidance { StepGuidance.age(profile.age) }

    /// How the currently selected goal stacks up against the age-based recommendation.
    private var verdict: (text: String, icon: String, color: Color) {
        let goal = profile.dailyStepGoal
        if goal < guidance.recommendedLow {
            return (
                "Below the \(guidance.bandLabel) range — an easy place to build the habit. You can always raise it later.",
                "arrow.down.circle",
                .blue
            )
        } else if goal > guidance.recommendedHigh {
            return (
                "Above the \(guidance.bandLabel) range — great for weight and fitness goals. Benefits tend to plateau around 10,000 (8,000 after 60).",
                "arrow.up.circle",
                .orange
            )
        } else {
            return (
                "Right in the \(guidance.bandLabel) recommended range — solid, sustainable target.",
                "checkmark.seal.fill",
                .green
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    title: "Your daily goal",
                    subtitle: "How many steps would you like to walk each day?"
                )

                // Big animated readout
                VStack(spacing: 4) {
                    Image(systemName: "shoeprints.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(profile.dailyStepGoal.formatted())
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("steps per day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Slider(
                    value: Binding(
                        get: { Double(profile.dailyStepGoal) },
                        set: { profile.dailyStepGoal = Int($0) }
                    ),
                    in: 2_000...20_000,
                    step: 250
                )
                .tint(.orange)
                .accessibilityLabel("Daily step goal")
                .accessibilityValue("\(profile.dailyStepGoal.formatted()) steps")

                // Quick-pick chips
                HStack(spacing: 8) {
                    ForEach(Self.quickPicks, id: \.self) { pick in
                        let isSelected = profile.dailyStepGoal == pick
                        Button {
                            withAnimation(.snappy) { profile.dailyStepGoal = pick }
                        } label: {
                            Text((Double(pick) / 1_000).formatted(.number.precision(.fractionLength(pick % 1_000 == 0 ? 0 : 1))) + "k")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? AnyShapeStyle(OnboardingStyle.accentGradient) : AnyShapeStyle(Color.orange.opacity(0.12)), in: Capsule())
                                .foregroundStyle(isSelected ? .white : .orange)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Age-correlated verdict for the currently selected goal
                let goalVerdict = verdict
                HStack(spacing: 8) {
                    Image(systemName: goalVerdict.icon)
                    Text(goalVerdict.text)
                        .font(.footnote.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(goalVerdict.color)
                .padding(12)
                .background(goalVerdict.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))

                // Recommendation based on activity level
                let recommended = StepGuidance.recommendedGoal(for: profile.age, activityLevel: profile.activityLevel)
                if profile.dailyStepGoal != recommended {
                    Button {
                        withAnimation(.snappy) { profile.dailyStepGoal = recommended }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                            Text("Recommended for your age & activity: \(recommended.formatted()) steps")
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundStyle(.orange)
                        .padding(12)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("You're at the recommended goal for your age & activity.")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(Color(red: 0.13, green: 0.55, blue: 0.24))
                    .padding(12)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                }

                GoalResearchCard(profile: $profile, guidance: guidance)
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

/// Summary of external research, personalized with the age, gender, weight and
/// activity level entered earlier in onboarding.
private struct GoalResearchCard: View {
    @Binding var profile: OnboardingProfile
    let guidance: AgeGuidance

    /// Gender-aware US step-average sentence (Healthline, 2010 pedometer study + 2017 global study).
    private var genderAverageNote: String {
        switch profile.gender {
        case .male:
            "Men average ~5,340 steps a day (vs ~4,912 for women) — the US average is ~4,774. People who track their steps walk ~2,500 more."
        case .female:
            "Women average ~4,912 steps a day (vs ~5,340 for men) — the US average is ~4,774. People who track their steps walk ~2,500 more."
        case .nonBinary, .preferNotToSay:
            "US adults average ~4,774 steps a day, and people who track their steps walk ~2,500 more than those who don't."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card header
            VStack(alignment: .leading, spacing: 2) {
                Label("The science behind your goal", systemImage: "chart.bar.fill")
                    .font(.headline)
                Text("Matched to your age (\(guidance.bandLabel)), weight and activity level.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                // 1. Age-based recommendation with one-tap apply of the range midpoint.
                HStack(alignment: .top, spacing: 10) {
                    researchIcon("calendar")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ages \(guidance.bandLabel): aim for \(guidance.recommendedLow.formatted())–\(guidance.recommendedHigh.formatted()) steps a day")
                            .font(.footnote.weight(.semibold))
                        Text(guidance.distanceTimeNote)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    let recommended = StepGuidance.recommendedGoal(for: profile.age, activityLevel: profile.activityLevel)
                    if profile.dailyStepGoal != recommended {
                        Button {
                            withAnimation(.snappy) { profile.dailyStepGoal = recommended }
                        } label: {
                            Text("Set \(recommended.formatted())")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.12), in: Capsule())
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                // 2. What people at this age actually walk (getsteps.app + Healthline).
                HStack(alignment: .top, spacing: 10) {
                    researchIcon("person.2")
                    Text(guidance.averageNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // 3. Calorie estimate at the currently selected goal, scaled by the user's weight.
                HStack(alignment: .top, spacing: 10) {
                    researchIcon("flame.fill")
                    Text("At \(profile.dailyStepGoal.formatted()) steps you'll burn roughly ~\(StepGuidance.estimatedCaloriesPerDay(stepGoal: profile.dailyStepGoal, weightKg: profile.weightKg)) calories a day at \(String(format: "%.0f", profile.weightKg)) kg — 8,000–10,000 steps ≈ 300–400 calories.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // 4. Sex / population averages (Healthline).
                HStack(alignment: .top, spacing: 10) {
                    researchIcon("figure.stand")
                    Text(genderAverageNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // 5. CDC minimum effective dose (Healthline).
                HStack(alignment: .top, spacing: 10) {
                    researchIcon("checkmark.seal.fill")
                    Text("CDC baseline: 150 min/week of brisk walking ≈ 2,000+ steps a day; 300 min ≈ 5,000 a day. Any goal above that moves the needle.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Sources: getsteps.app — 2026 age recommendations · Healthline — average steps by age, sex & country. Estimates, not medical advice.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        }
    }

    private func researchIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .frame(width: 26, height: 26)
            .background(Color.orange.opacity(0.12), in: Circle())
    }
}

// MARK: - Step 4: Motivation & avatar

struct MotivationStep: View {
    @Binding var profile: OnboardingProfile

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingHeader(
                    title: "What drives you?",
                    subtitle: "Pick everything that resonates — we'll use it to keep you motivated."
                )

                // Motivations — multi-select chips
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Motivation.allCases) { motivation in
                        let isSelected = profile.motivations.contains(motivation)
                        Button {
                            withAnimation(.snappy) {
                                if profile.motivations.contains(motivation) {
                                    profile.motivations.remove(motivation)
                                } else {
                                    profile.motivations.insert(motivation)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: motivation.symbolName)
                                    .font(.subheadline)
                                Text(motivation.title)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                            .background(isSelected ? Color.orange.opacity(0.15) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(isSelected ? Color.orange : Color.clear, lineWidth: 1.5)
                            }
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }

                // Avatar — motivational emoji the app can use in celebrations & reminders.
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your walk buddy", systemImage: "face.smiling")
                        .font(.headline)
                    Text("Choose an emoji to cheer you on.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(OnboardingProfile.avatarOptions, id: \.self) { emoji in
                            let isSelected = profile.avatarEmoji == emoji
                            Button {
                                withAnimation(.snappy) { profile.avatarEmoji = emoji }
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 52, height: 52)
                                    .background(isSelected ? AnyShapeStyle(OnboardingStyle.accentGradient) : AnyShapeStyle(Color(nsColor: .controlBackgroundColor)), in: Circle())
                                    .scaleEffect(isSelected ? 1.15 : 1)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Avatar \(emoji)")
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                }

                // Suggested micro-activities — optional; used for "behind on your goal" nudges.
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pick activities you're happy to do", systemImage: "checklist")
                        .font(.headline)
                    Text("Optional — we'll suggest these when you're behind your goal.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        ForEach(SuggestedActivity.allCases) { activity in
                            let isSelected = profile.suggestedActivities.contains(activity)
                            OnboardingSelectableRow(
                                symbolName: activity.symbolName,
                                title: activity.title,
                                subtitle: activity.explanation,
                                isSelected: isSelected
                            ) {
                                withAnimation(.snappy) {
                                    if profile.suggestedActivities.contains(activity) {
                                        profile.suggestedActivities.remove(activity)
                                    } else {
                                        profile.suggestedActivities.insert(activity)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Step 5: Reminders

struct RemindersStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
            OnboardingHeader(
                title: "Gentle nudges",
                subtitle: "Pick the days you'd like a nudge."
            )

            Toggle(isOn: $profile.reminderEnabled.animation(.snappy)) {
                Label("Step reminder", systemImage: "bell.badge")
                    .font(.headline)
            }
            .tint(.orange)
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))

            if profile.reminderEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Remind me at", systemImage: "clock")
                        .font(.headline)
                    DatePicker(
                        "Time of day",
                        selection: $profile.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .frame(maxWidth: .infinity, maxHeight: 140, alignment: .center)
                    .clipped()
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .transition(.opacity.combined(with: .move(edge: .top)))

                // Day-of-week multi-select
                VStack(alignment: .leading, spacing: 8) {
                    Label("Active on", systemImage: "calendar")
                        .font(.headline)
                    HStack(spacing: 4) {
                        ForEach(Weekday.allCases) { day in
                            let isSelected = profile.reminderDays.contains(day)
                            Button {
                                withAnimation(.snappy) { toggleDay(day) }
                            } label: {
                                Text(day.shortLabel)
                                    .font(.caption2.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(isSelected ? AnyShapeStyle(OnboardingStyle.accentGradient) : AnyShapeStyle(Color(nsColor: .controlBackgroundColor)), in: RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(isSelected ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                    Text("At least one day is required while the reminder is on.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Label {
                Text("We only nudge when you're behind on your goal — never to nag.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.orange)
            }

            Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    /// Toggles a reminder day, keeping at least one day selected while the reminder is on.
    private func toggleDay(_ day: Weekday) {
        if profile.reminderDays.contains(day) {
            if profile.reminderDays.count > 1 {
                profile.reminderDays.remove(day)
            }
        } else {
            profile.reminderDays.insert(day)
        }
    }
}

// MARK: - Step 6: Summary

struct SummaryStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero: emoji in gradient ring + name
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(OnboardingStyle.accentGradient)
                            .frame(width: 96, height: 96)
                        Text(profile.avatarEmoji)
                            .font(.system(size: 52))
                    }
                    Text("All set, \(profile.name.trimmingCharacters(in: .whitespaces))!")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("Here's your walking plan:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats card
                VStack(spacing: 0) {
                    summaryRow(symbolName: "shoeprints.fill", label: "Daily goal", value: "\(profile.dailyStepGoal.formatted()) steps")
                    Divider().padding(.leading, 52)
                    summaryRow(symbolName: "figure.run", label: "Activity level", value: profile.activityLevel.title)
                    Divider().padding(.leading, 52)
                    summaryRow(symbolName: "ruler", label: "Height · Weight", value: "\(String(format: "%.0f", profile.heightCm)) cm · \(String(format: "%.0f", profile.weightKg)) kg")
                    Divider().padding(.leading, 52)
                    summaryRow(symbolName: "calendar", label: "Age · Gender", value: "\(profile.age) · \(profile.gender.label)")
                    Divider().padding(.leading, 52)
                    summaryRow(
                        symbolName: "bell.badge",
                        label: "Reminder",
                        value: profile.reminderEnabled
                            ? "\(profile.reminderDaysSummary) · \(profile.reminderTimeLabel)"
                            : "Off"
                    )
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 20))

                // Motivations as tags
                if !profile.orderedMotivations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(profile.orderedMotivations) { motivation in
                                Label(motivation.title, systemImage: motivation.symbolName)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.12), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func summaryRow(symbolName: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 28)
            Text(label)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
}
