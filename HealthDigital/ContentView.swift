//
//  ContentView.swift
//  StepsGoals
//
//  Created by Training-08 on 14/11/26.
//

import SwiftUI

struct ContentView: View {
    /// Flipped by OnboardingView when the user finishes the flow.
    @AppStorage(OnboardingPersistence.completedKey) private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            HomePlaceholderView()
        } else {
            OnboardingView()
        }
    }
}

/// Placeholder home shown after onboarding completes. The real dashboard is built later.
private struct HomePlaceholderView: View {
    @AppStorage(OnboardingPersistence.completedKey) private var hasCompletedOnboarding = false
    private let profile = OnboardingPersistence.load()

    var body: some View {
        VStack(spacing: 16) {
            Text(profile?.avatarEmoji ?? "🚶")
                .font(.system(size: 72))
            Text("Welcome, \(profile?.name ?? "walker")!")
                .font(.title.bold())
            if let profile {
                Label("Daily goal: \(profile.dailyStepGoal.formatted()) steps", systemImage: "shoeprints.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            Text("Congrats on finishing onboarding! Your dashboard is coming soon.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            // Temporary escape hatch while iterating on onboarding during development.
            Button("Reset Onboarding") {
                hasCompletedOnboarding = false
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
