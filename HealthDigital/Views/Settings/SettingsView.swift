//
//  SettingsView.swift
//  HealthDigital
//
//  Same choices as onboarding, editable anytime.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Profile", systemImage: "person.crop.circle") { ProfileSettings() }
            Tab("Goal", systemImage: "target") { GoalSettings() }
            Tab("Activities", systemImage: "figure.walk") { ActivitySettings() }
            Tab("Reminder", systemImage: "bell") { ReminderSettingsView() }
            Tab("Privacy", systemImage: "hand.raised") { PrivacySettings() }
            #if DEBUG
            Tab("Developer", systemImage: "hammer") { DeveloperSettings() }
            #endif
        }
        .frame(width: 560)
        .scenePadding()
    }
}

private struct ProfileSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            TextField("Name", text: $model.profile.name)
            TextField("Age", value: $model.profile.age, format: .number)
            Picker("Gender", selection: $model.profile.gender) {
                ForEach(Gender.allCases) { Text($0.label).tag($0) }
            }
            TextField("Height (cm)", value: $model.profile.heightCm, format: .number)
            TextField("Weight (kg)", value: $model.profile.weightKg, format: .number)
            Text("Stored on this Mac only.").font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

private struct GoalSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Picker("Activity level", selection: $model.profile.activityLevel) {
                ForEach(ActivityLevel.allCases) { Text($0.title).tag($0) }
            }
            LabeledContent("Daily goal") {
                GoalStepper(goal: $model.profile.dailyGoal)
            }
            Button("Use recommended goal for your age and activity (\(model.profile.recommendedGoal.grouped))") {
                model.profile.dailyGoal = model.profile.recommendedGoal
            }
            Section("What drives you") {
                MotivationChips(selection: $model.profile.motivations)
                    .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }
}

private struct ActivitySettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                ActivityTiles(selection: $model.profile.activities)
                    .padding(.vertical, 4)
            } footer: {
                Text(model.profile.activities.isEmpty
                     ? "With none selected, the reminder just asks you to stand and stretch."
                     : "The daily reminder rotates through the \(model.profile.activities.count) activities you picked.")
            }
        }
        .formStyle(.grouped)
    }
}

private struct ReminderSettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Toggle("Step reminder", isOn: $model.profile.reminderEnabled)
            Group {
                LabeledContent("Remind me at") {
                    ReminderTimeStepper(minutes: $model.profile.reminderMinutes)
                }
                LabeledContent("Active on") {
                    WeekdayPicker(selection: $model.profile.reminderDays)
                }
            }
            .disabled(!model.profile.reminderEnabled)
            Text(summary).font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var summary: String {
        let p = model.profile
        guard p.reminderEnabled else { return "Reminders are off. Step Hub still tracks your steps." }
        return p.reminderDays.isEmpty ? "Pick at least one day." : "One reminder at \(p.reminderTimeLabel), \(p.reminderDaysSummary.lowercased())."
    }
}

private struct PrivacySettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WatchConsentStatus(consent: model.consent, aiUnavailableReason: model.generator.modelUnavailableReason)
                Divider()
                Label("Where your data stays", systemImage: "lock.laptopcomputer").font(.subheadline.weight(.semibold))
                Text("On your Watch and this Mac. Insights are written by Apple’s on-device model; nothing is sent to a server. Insights are not medical advice.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(height: 380)
    }
}

#if DEBUG
private struct DeveloperSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section("Sample data") {
                Picker("Scenario", selection: Binding(get: { model.sampleScenario ?? .normal }, set: { model.sampleScenario = $0 })) {
                    ForEach(SampleScenario.allCases) { Text($0.rawValue).tag($0) }
                }
                Text("Real data will come from the Watch integration via StepDataSource.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Consent") {
                Button("Simulate Allow from Watch") { model.simulateWatchConsent() }
            }
            Section("Daily flow") {
                Button("Trigger today’s reminder now") { model.triggerReminderNow() }
                Button("Reset today’s activity") { model.resetToday() }
            }
            Section {
                Button("Reset onboarding", role: .destructive) { model.resetOnboarding() }
            }
        }
        .formStyle(.grouped)
    }
}
#endif
