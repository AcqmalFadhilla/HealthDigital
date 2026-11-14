//
//  OnboardingView.swift
//  HealthDigital
//
//  Consent → About you → Activity level → Daily goal → What drives you → Activities → Step reminder.
//  Everything here can be changed later in Settings.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    enum Step: Int, CaseIterable {
        case consent, about, level, goal, drives, activities, reminder
    }

    @State private var step: Step = .consent
    @State private var profile = UserProfile()
    @State private var ageText = ""
    @State private var heightText = ""
    @State private var weightText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: 13).fill(.orange))
                        .padding(.bottom, 4)
                    Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(title).font(.title.bold()).multilineTextAlignment(.center)
                    Text(subtitle).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .padding(.bottom, 12)
                    content
                        .frame(maxWidth: 560)
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            }
            Divider()
            footer
        }
        .frame(minWidth: 640, minHeight: 600)
        .onAppear {
            profile = model.profile
        }
    }

    private var title: String {
        switch step {
        case .consent: "Allow on your Apple Watch"
        case .about: "Tell us about you"
        case .level: "How active are you?"
        case .goal: "Your daily goal"
        case .drives: "What drives you?"
        case .activities: "Activities you’re happy to do"
        case .reminder: "Step reminder"
        }
    }

    private var subtitle: String {
        switch step {
        case .consent: "Your steps come from your Watch, so that’s where you choose what’s shared, why, and where it stays."
        case .about: "Used to estimate distance and suggest a goal."
        case .level: "Think about a normal workday."
        case .goal: "Suggested for \(profile.activityLevel.label.lowercased()): \(profile.activityLevel.suggestedGoal.grouped) steps."
        case .drives: "Pick any that apply. Insights may mention them."
        case .activities: "Each day’s reminder suggests one of these."
        case .reminder: "One reminder a day from the menu bar, with one activity to do."
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .consent:
            VStack(alignment: .leading, spacing: 12) {
                WatchConsentStatus(consent: model.consent, aiUnavailableReason: model.generator.modelUnavailableReason)
                #if DEBUG
                if model.awaitingWatchConsent {
                    Button("Simulate Allow from Watch (debug)") { model.simulateWatchConsent() }
                        .buttonStyle(.link).font(.caption)
                }
                #endif
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .about:
            Form {
                TextField("Name", text: $profile.name, prompt: Text("Your name"))
                TextField("Age", text: $ageText, prompt: Text("Years"))
                Picker("Gender", selection: $profile.gender) {
                    ForEach(Gender.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                TextField("Height (cm)", text: $heightText, prompt: Text("cm"))
                TextField("Weight (kg)", text: $weightText, prompt: Text("kg"))
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 280)
        case .level:
            VStack(spacing: 8) {
                ForEach(ActivityLevel.allCases) { level in
                    let on = profile.activityLevel == level
                    Button {
                        profile.activityLevel = level
                        profile.dailyGoal = level.suggestedGoal
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: on ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(on ? Color.accentColor : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.label).font(.headline)
                                Text(level.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(on ? Color.accentColor.opacity(0.08) : .clear))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(on ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: on ? 2 : 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        case .goal:
            VStack(spacing: 14) {
                GoalStepper(goal: $profile.dailyGoal, large: true)
                Text("Changes in steps of 500.").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.top, 12)
        case .drives:
            MotivationChips(selection: $profile.motivations)
        case .activities:
            ActivityTiles(selection: $profile.activities)
        case .reminder:
            Form {
                Toggle("Step reminder", isOn: $profile.reminder.isEnabled)
                    .toggleStyle(.switch)
                Group {
                    LabeledContent("Remind me at") {
                        ReminderTimeStepper(minutes: $profile.reminder.minutesAfterMidnight)
                    }
                    LabeledContent("Active on") {
                        WeekdayPicker(selection: $profile.reminder.activeWeekdays)
                    }
                }
                .disabled(!profile.reminder.isEnabled)
                .opacity(profile.reminder.isEnabled ? 1 : 0.4)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 200)
        }
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.self) { s in
                    Capsule().fill(s == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: s == step ? 18 : 6, height: 6)
                }
            }
            .accessibilityHidden(true)
            Spacer()
            if step != .consent {
                Button("Back") { move(-1) }
            }
            if step == .drives || step == .activities || (step == .consent && model.awaitingWatchConsent) {
                Button(step == .consent ? "Do it later" : "Skip") { move(1) }.buttonStyle(.borderless)
            }
            Button(step == .reminder ? "Start Using Step Hub" : "Continue") {
                if step == .reminder { finish() } else { move(1) }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(step == .consent && model.awaitingWatchConsent)
        }
        .padding(.horizontal, 24)
        .frame(height: 60)
    }

    private func move(_ delta: Int) {
        withAnimation(.snappy) {
            step = Step(rawValue: step.rawValue + delta) ?? step
        }
    }

    private func finish() {
        profile.age = Int(ageText)
        profile.heightCm = Double(heightText.replacingOccurrences(of: ",", with: "."))
        profile.weightKg = Double(weightText.replacingOccurrences(of: ",", with: "."))
        model.profile = profile
        model.completeOnboarding()
    }
}
