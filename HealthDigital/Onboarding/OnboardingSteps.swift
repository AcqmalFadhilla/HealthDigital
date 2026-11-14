//
//  OnboardingSteps.swift
//  StepsGoals
//
//  Created by Training-08 on 14/11/26.
//
//  Native macOS presentation (grouped forms, standard controls). Content and the
//  goal recommendation logic (StepGuidance) are unchanged.
//

import SwiftUI

// MARK: - Shared

/// Icon + title + subtitle shown at the top of each step.
struct OnboardingHeader: View {
    let symbolName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbolName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(.orange))
                .padding(.bottom, 4)
                .accessibilityHidden(true)
            Text(title)
                .font(.title.bold())
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 112, height: 112)
                .background(RoundedRectangle(cornerRadius: 26).fill(.orange))
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Step Hub")
                    .font(.largeTitle.bold())
                Text("Small steps, big changes.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Quick preview of what the app personalizes for the user.
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("A daily step goal that fits your life", systemImage: "target")
                    Label("Friendly reminders to keep you moving", systemImage: "bell.badge")
                    Label("Motivation tuned to why you walk", systemImage: "flame.fill")
                }
                .font(.body)
                .symbolRenderingMode(.multicolor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            .frame(maxWidth: 420)

            Text("Answer a few quick questions and we’ll tailor everything to you. It takes under a minute.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(40)
    }
}

// MARK: - Step 1: About you

struct AboutYouStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $profile.name, prompt: Text("Your first name"))
                    .textContentType(.name)
                    .autocorrectionDisabled()
                Stepper(value: $profile.age, in: 10...100) {
                    LabeledContent("Age") {
                        Text("\(profile.age) years").monospacedDigit()
                    }
                }
                Picker("Gender", selection: $profile.gender) {
                    ForEach(Gender.allCases) { gender in
                        Label(gender.label, systemImage: gender.symbolName).tag(gender)
                    }
                }
            } header: {
                OnboardingHeader(symbolName: "person.text.rectangle", title: "About you", subtitle: "Tell us the basics.")
            } footer: {
                Text("Gender is optional — used only to tailor insights.")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Step 2: Body & activity

struct BodyMetricsStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        Form {
            Section {
                MetricSlider(label: "Height", value: $profile.heightCm, range: 130...210, step: 1,
                             readout: String(format: "%.0f cm", profile.heightCm), secondary: profile.heightImperial)
                MetricSlider(label: "Weight", value: $profile.weightKg, range: 35...160, step: 0.5,
                             readout: String(format: "%.1f kg", profile.weightKg), secondary: profile.weightImperial)
            } header: {
                OnboardingHeader(symbolName: "ruler", title: "Your body",
                                 subtitle: "Height, weight and activity level — used to estimate calorie burn. Never shared.")
            }

            Section {
                Picker("Activity level", selection: $profile.activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(level.title)
                            Text(level.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                        .tag(level)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            } header: {
                Text("Activity level")
            } footer: {
                Text("We’ll use this to recommend your daily goal.")
            }
        }
        .formStyle(.grouped)
    }
}

/// Slider row with a readout and secondary (imperial) unit.
private struct MetricSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let readout: String
    let secondary: String

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 12) {
                Slider(value: $value, in: range, step: step)
                    .frame(width: 220)
                    .accessibilityLabel(label)
                    .accessibilityValue(readout)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(readout).monospacedDigit()
                    Text(secondary).font(.caption).foregroundStyle(.secondary)
                }
                .frame(width: 72, alignment: .trailing)
            }
        }
    }
}

// MARK: - Step 3: Step goal

struct StepGoalStep: View {
    @Binding var profile: OnboardingProfile

    private static let quickPicks = [5_000, 7_500, 10_000, 12_500, 15_000]

    /// Age-based guidance derived from the age the user entered earlier.
    private var guidance: AgeGuidance { StepGuidance.age(profile.age) }

    private var recommended: Int {
        StepGuidance.recommendedGoal(for: profile.age, activityLevel: profile.activityLevel)
    }

    /// How the currently selected goal stacks up against the age-based recommendation.
    private var verdict: (text: String, icon: String, color: Color) {
        let goal = profile.dailyStepGoal
        if goal < guidance.recommendedLow {
            return ("Below the \(guidance.bandLabel) range — an easy place to build the habit. You can always raise it later.",
                    "arrow.down.circle", .blue)
        } else if goal > guidance.recommendedHigh {
            return ("Above the \(guidance.bandLabel) range — great for weight and fitness goals. Benefits tend to plateau around 10,000 (8,000 after 60).",
                    "arrow.up.circle", .orange)
        } else {
            return ("Right in the \(guidance.bandLabel) recommended range — solid, sustainable target.",
                    "checkmark.seal.fill", .green)
        }
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 2) {
                    Text(profile.dailyStepGoal.formatted())
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("steps per day").font(.callout).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .animation(.snappy, value: profile.dailyStepGoal)

                Slider(value: Binding(get: { Double(profile.dailyStepGoal) },
                                      set: { profile.dailyStepGoal = Int($0) }),
                       in: 2_000...20_000, step: 250) {
                    Text("Daily step goal")
                } minimumValueLabel: {
                    Text("2k").font(.caption)
                } maximumValueLabel: {
                    Text("20k").font(.caption)
                }
                .labelsHidden()
                .accessibilityValue("\(profile.dailyStepGoal.formatted()) steps")

                HStack(spacing: 8) {
                    ForEach(Self.quickPicks, id: \.self) { pick in
                        Button(Self.label(for: pick)) { profile.dailyStepGoal = pick }
                            .buttonStyle(.bordered)
                            .tint(profile.dailyStepGoal == pick ? .accentColor : nil)
                            .accessibilityAddTraits(profile.dailyStepGoal == pick ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity)
            } header: {
                OnboardingHeader(symbolName: "target", title: "Your daily goal",
                                 subtitle: "How many steps would you like to walk each day?")
            }

            Section {
                let v = verdict
                Label(v.text, systemImage: v.icon)
                    .foregroundStyle(v.color)

                LabeledContent {
                    if profile.dailyStepGoal != recommended {
                        Button("Use \(recommended.formatted())") { profile.dailyStepGoal = recommended }
                    } else {
                        Label("Selected", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                } label: {
                    Label("Recommended for your age & activity: \(recommended.formatted()) steps", systemImage: "wand.and.stars")
                }
            }

            GoalResearchSection(profile: $profile, guidance: guidance)
        }
        .formStyle(.grouped)
    }

    private static func label(for pick: Int) -> String {
        (Double(pick) / 1_000).formatted(.number.precision(.fractionLength(pick % 1_000 == 0 ? 0 : 1))) + "k"
    }
}

/// Summary of external research, personalized with the age, gender, weight and
/// activity level entered earlier in onboarding.
private struct GoalResearchSection: View {
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
            "US adults average ~4,774 steps a day, and people who track their steps walk ~2,500 more than those who don’t."
        }
    }

    var body: some View {
        Section {
            LabeledContent {
                let recommended = StepGuidance.recommendedGoal(for: profile.age, activityLevel: profile.activityLevel)
                if profile.dailyStepGoal != recommended {
                    Button("Set \(recommended.formatted())") { profile.dailyStepGoal = recommended }
                        .controlSize(.small)
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ages \(guidance.bandLabel): aim for \(guidance.recommendedLow.formatted())–\(guidance.recommendedHigh.formatted()) steps a day")
                        Text(guidance.distanceTimeNote).font(.caption).foregroundStyle(.secondary)
                    }
                } icon: { Image(systemName: "calendar").foregroundStyle(.orange) }
            }
            researchRow("person.2", guidance.averageNote)
            researchRow("flame.fill", "At \(profile.dailyStepGoal.formatted()) steps you’ll burn roughly ~\(StepGuidance.estimatedCaloriesPerDay(stepGoal: profile.dailyStepGoal, weightKg: profile.weightKg)) calories a day at \(String(format: "%.0f", profile.weightKg)) kg — 8,000–10,000 steps ≈ 300–400 calories.")
            researchRow("figure.stand", genderAverageNote)
            researchRow("checkmark.seal", "CDC baseline: 150 min/week of brisk walking ≈ 2,000+ steps a day; 300 min ≈ 5,000 a day. Any goal above that moves the needle.")
        } header: {
            VStack(alignment: .leading, spacing: 2) {
                Text("The science behind your goal")
                Text("Matched to your age (\(guidance.bandLabel)), weight and activity level.")
                    .font(.caption).foregroundStyle(.secondary).textCase(nil)
            }
        } footer: {
            Text("Sources: getsteps.app — 2026 age recommendations · Healthline — average steps by age, sex & country. Estimates, not medical advice.")
        }
    }

    private func researchRow(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol).foregroundStyle(.orange)
        }
    }
}

// MARK: - Step 4: Motivation & avatar

struct MotivationStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        Form {
            Section {
                ForEach(Motivation.allCases) { motivation in
                    Toggle(isOn: membership(motivation, in: \.motivations)) {
                        Label(motivation.title, systemImage: motivation.symbolName)
                    }
                    .toggleStyle(.checkbox)
                }
            } header: {
                OnboardingHeader(symbolName: "flame.fill", title: "What drives you?",
                                 subtitle: "Pick everything that resonates — we’ll use it to keep you motivated.")
            }

            // Avatar — motivational emoji the app can use in celebrations & reminders.
            Section {
                HStack(spacing: 6) {
                    ForEach(OnboardingProfile.avatarOptions, id: \.self) { emoji in
                        let isSelected = profile.avatarEmoji == emoji
                        Button { profile.avatarEmoji = emoji } label: {
                            Text(emoji).font(.title2).frame(width: 30, height: 30)
                        }
                        .buttonStyle(.bordered)
                        .tint(isSelected ? .accentColor : nil)
                        .accessibilityLabel("Avatar \(emoji)")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            } header: {
                Text("Your walk buddy")
            } footer: {
                Text("Choose an emoji to cheer you on.")
            }

            Section {
                ForEach(SuggestedActivity.allCases) { activity in
                    Toggle(isOn: membership(activity, in: \.suggestedActivities)) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                Text(activity.explanation).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: activity.symbolName).foregroundStyle(.orange) }
                    }
                    .toggleStyle(.checkbox)
                }
            } header: {
                Text("Pick activities you’re happy to do")
            } footer: {
                Text("Optional — your daily reminder suggests one of these.")
            }
        }
        .formStyle(.grouped)
    }

    private func membership<T: Hashable>(_ item: T, in keyPath: WritableKeyPath<OnboardingProfile, Set<T>>) -> Binding<Bool> {
        Binding(
            get: { profile[keyPath: keyPath].contains(item) },
            set: { on in
                if on { profile[keyPath: keyPath].insert(item) } else { profile[keyPath: keyPath].remove(item) }
            }
        )
    }
}

// MARK: - Step 5: Reminders

struct RemindersStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $profile.reminderEnabled.animation(.snappy)) {
                    Label("Step reminder", systemImage: "bell.badge")
                }
                .toggleStyle(.switch)

                if profile.reminderEnabled {
                    DatePicker(selection: $profile.reminderTime, displayedComponents: .hourAndMinute) {
                        Label("Remind me at", systemImage: "clock")
                    }
                    LabeledContent {
                        HStack(spacing: 4) {
                            ForEach(Weekday.allCases) { day in
                                Toggle(day.shortLabel, isOn: dayBinding(day))
                                    .toggleStyle(.button)
                            }
                        }
                    } label: {
                        Label("Active on", systemImage: "calendar")
                    }
                }
            } header: {
                OnboardingHeader(symbolName: "bell.badge", title: "Gentle nudges",
                                 subtitle: "Pick the days you’d like a nudge.")
            } footer: {
                if profile.reminderEnabled {
                    Text("One reminder a day at this time from the menu bar, with one activity to do. At least one day is required while the reminder is on.")
                }
            }
        }
        .formStyle(.grouped)
    }

    /// Toggles a reminder day, keeping at least one day selected while the reminder is on.
    private func dayBinding(_ day: Weekday) -> Binding<Bool> {
        Binding(
            get: { profile.reminderDays.contains(day) },
            set: { on in
                if on {
                    profile.reminderDays.insert(day)
                } else if profile.reminderDays.count > 1 {
                    profile.reminderDays.remove(day)
                }
            }
        )
    }
}

// MARK: - Step 6: Summary

struct SummaryStep: View {
    @Binding var profile: OnboardingProfile

    var body: some View {
        Form {
            Section {
                LabeledContent("Daily goal", value: "\(profile.dailyStepGoal.formatted()) steps")
                LabeledContent("Activity level", value: profile.activityLevel.title)
                LabeledContent("Height · Weight", value: "\(String(format: "%.0f", profile.heightCm)) cm · \(String(format: "%.0f", profile.weightKg)) kg")
                LabeledContent("Age · Gender", value: "\(profile.age) · \(profile.gender.label)")
                LabeledContent("Reminder", value: profile.reminderEnabled
                               ? "\(profile.reminderDaysSummary) · \(profile.reminderTimeLabel)"
                               : "Off")
                if !profile.orderedMotivations.isEmpty {
                    LabeledContent("What drives you", value: profile.orderedMotivations.map(\.title).joined(separator: ", "))
                }
                if !profile.orderedSuggestedActivities.isEmpty {
                    LabeledContent("Activities", value: profile.orderedSuggestedActivities.map(\.title).joined(separator: ", "))
                }
            } header: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.avatarEmoji)
                        .font(.system(size: 34))
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.orange.opacity(0.15)))
                        .accessibilityHidden(true)
                    Text("All set, \(profile.name.trimmingCharacters(in: .whitespaces))!")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text("Here’s your walking plan:")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .textCase(nil)
                .padding(.bottom, 8)
            }
        }
        .formStyle(.grouped)
    }
}
