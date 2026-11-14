//
//  ContentView.swift
//  StepsGoals
//
//  Created by Training-08 on 14/11/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    /// Flipped by OnboardingView when the user finishes the flow.
    @AppStorage(OnboardingPersistence.completedKey) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                // The real dashboard (replaces the earlier home placeholder).
                RootView()
            } else {
                OnboardingView()
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if completed { model.onboardingCompleted() }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
