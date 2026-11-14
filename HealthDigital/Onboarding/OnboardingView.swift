//
//  OnboardingView.swift
//  StepsGoals
//
//  Created by Training-08 on 14/11/26.
//

import SwiftUI

/// Multi-step onboarding flow shown on first launch, in a native macOS setup-assistant style.
/// Collects name, age, gender, body metrics, activity level, daily step goal,
/// motivations, a personal avatar and reminder preferences.
struct OnboardingView: View {
    /// Set by the app once the user finishes; flips the root view to the home screen.
    @AppStorage(OnboardingPersistence.completedKey) private var hasCompletedOnboarding = false

    /// The steps in display order. Raw values double as progress.
    private enum Step: Int, CaseIterable {
        case welcome
        case aboutYou
        case bodyMetrics
        case stepGoal
        case motivation
        case reminders
        case summary

        var showsProgress: Bool { self != .welcome }
    }

    @State private var step: Step = .welcome
    @State private var profile = OnboardingProfile.default

    var body: some View {
        VStack(spacing: 0) {
            stepContent
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(step)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: step)

            Divider()
            bottomBar
        }
        .frame(minWidth: 680, minHeight: 640)
    }

    // MARK: - Content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .aboutYou: AboutYouStep(profile: $profile)
        case .bodyMetrics: BodyMetricsStep(profile: $profile)
        case .stepGoal: StepGoalStep(profile: $profile)
        case .motivation: MotivationStep(profile: $profile)
        case .reminders: RemindersStep(profile: $profile)
        case .summary: SummaryStep(profile: $profile)
        }
    }

    // MARK: - Bottom bar (progress, back, primary action)

    private var canContinue: Bool {
        // Name is the only required field in the flow.
        step != .aboutYou || !profile.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var primaryLabel: String {
        switch step {
        case .welcome: "Get Started"
        case .summary: "Start Using Step Hub"
        default: "Continue"
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            if step.showsProgress {
                HStack(spacing: 6) {
                    ForEach(1..<Step.allCases.count, id: \.self) { index in
                        Capsule()
                            .fill(index == step.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: index == step.rawValue ? 18 : 6, height: 6)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Onboarding progress")
                .accessibilityValue("Step \(step.rawValue) of \(Step.allCases.count - 1)")
                Text("Step \(step.rawValue) of \(Step.allCases.count - 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if step != .welcome {
                Button("Back") { navigate(by: -1) }
                    .keyboardShortcut(.cancelAction)
            }
            Button(primaryLabel, action: primaryAction)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canContinue)
        }
        .controlSize(.large)
        .padding(.horizontal, 20)
        .frame(height: 60)
    }

    private func primaryAction() {
        if step == .summary { finishOnboarding() } else { navigate(by: 1) }
    }

    private func navigate(by delta: Int) {
        step = Step(rawValue: step.rawValue + delta) ?? step
    }

    private func finishOnboarding() {
        let trimmed = OnboardingProfile(
            name: profile.name.trimmingCharacters(in: .whitespaces),
            age: profile.age,
            gender: profile.gender,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            activityLevel: profile.activityLevel,
            dailyStepGoal: profile.dailyStepGoal,
            motivations: profile.motivations,
            avatarEmoji: profile.avatarEmoji,
            reminderEnabled: profile.reminderEnabled,
            reminderTime: profile.reminderTime,
            reminderDays: profile.reminderDays,
            suggestedActivities: profile.suggestedActivities
        )
        OnboardingPersistence.save(trimmed)
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
}
