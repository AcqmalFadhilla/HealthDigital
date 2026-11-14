//
//  OnboardingView.swift
//  StepsGoals
//
//  Created by Training-08 on 14/11/26.
//

import SwiftUI

/// Multi-step onboarding flow shown on first launch.
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
            if step.showsProgress {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            // Active step content, cross-fading/sliding on navigation.
            ZStack {
                stepContent
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .animation(.snappy, value: step)

            bottomBar
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .background(
            OnboardingStyle.backgroundGradient
                .ignoresSafeArea()
        )
        .background(Color(nsColor: .underPageBackgroundColor).ignoresSafeArea())
    }

    // MARK: - Progress

    private var progressFraction: Double {
        let total = Step.allCases.count - 1
        return total > 0 ? Double(step.rawValue) / Double(total) : 0
    }

    private var progressBar: some View {
        VStack(alignment: .trailing, spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.orange.opacity(0.15))
                    Capsule()
                        .fill(OnboardingStyle.accentGradient)
                        .frame(width: max(8, geometry.size.width * progressFraction))
                }
            }
            .frame(height: 6)

            Text("Step \(step.rawValue) of \(Step.allCases.count - 1)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(step.rawValue) of \(Step.allCases.count - 1)")
    }

    // MARK: - Content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStep()
        case .aboutYou:
            AboutYouStep(profile: $profile)
        case .bodyMetrics:
            BodyMetricsStep(profile: $profile)
        case .stepGoal:
            StepGoalStep(profile: $profile)
        case .motivation:
            MotivationStep(profile: $profile)
        case .reminders:
            RemindersStep(profile: $profile)
        case .summary:
            SummaryStep(profile: $profile)
        }
    }

    // MARK: - Bottom bar (back / primary action)

    private var canContinue: Bool {
        // Name is the only required field in the flow.
        step != .aboutYou || !profile.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var primaryLabel: String {
        switch step {
        case .welcome: "Get Started"
        case .summary: "Let's Go!"
        default: "Continue"
        }
    }

    private var primaryIcon: String? {
        switch step {
        case .welcome: "arrow.right"
        case .summary: "shoeprints.fill"
        default: nil
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .welcome {
                Button {
                    navigate(to: Step(rawValue: step.rawValue - 1) ?? .welcome)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 52, height: 52)
                        .background(Color(nsColor: .controlBackgroundColor), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    Text(primaryLabel)
                        .font(.headline)
                    if let primaryIcon {
                        Image(systemName: primaryIcon)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    canContinue
                        ? AnyShapeStyle(OnboardingStyle.accentGradient)
                        : AnyShapeStyle(Color(.quaternarySystemFill)),
                    in: Capsule()
                )
                .foregroundStyle(canContinue ? Color.white : Color(nsColor: .secondaryLabelColor))
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
        }
        .safeAreaPadding(.bottom, 8)
    }

    private func primaryAction() {
        switch step {
        case .summary:
            finishOnboarding()
        default:
            navigate(to: Step(rawValue: step.rawValue + 1) ?? .summary)
        }
    }

    private func navigate(to newStep: Step) {
        withAnimation(.snappy) { step = newStep }
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
