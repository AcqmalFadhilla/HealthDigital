//
//  WatchConsentView.swift
//  HealthDigitalWatch
//
//  Consent: what, why, where — matching the paper prototype's first screen.
//

import SwiftUI

struct WatchRootView: View {
    @Environment(WatchConsentModel.self) private var model

    var body: some View {
        NavigationStack {
            if model.hasConsented {
                WatchSharingStatusView()
            } else {
                WatchConsentView()
            }
        }
    }
}

struct WatchConsentView: View {
    @Environment(WatchConsentModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List {
            Section {
                VStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.orange))
                    Text("Step Hub would like to use your step data")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section("What") {
                Toggle("Step count", isOn: $model.draft.useStepData)
                Toggle("Activity check-ins", isOn: $model.draft.useActivityLog)
                Toggle("On-device insights", isOn: $model.draft.useOnDeviceAI)
            }

            Section("Why") {
                Text("To show your Mac how far you are from your daily goal, remind you once a day, and explain your progress.")
                    .font(.footnote)
            }

            Section("Where") {
                Text("Stays on your Watch and Mac. Insights are written by Apple’s on-device model on your Mac — nothing goes to a server. Not medical advice.")
                    .font(.footnote)
            }

            Section {
                Button {
                    Task { await model.allow() }
                } label: {
                    if model.isRequesting {
                        ProgressView()
                    } else {
                        Text("Allow").frame(maxWidth: .infinity)
                    }
                }
                .tint(.orange)
                .disabled(model.isRequesting)
            } footer: {
                Text("Step count is needed for progress on your Mac. You can change this anytime here.")
            }
        }
        .navigationTitle("Step Hub")
    }
}

struct WatchSharingStatusView: View {
    @Environment(WatchConsentModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List {
            Section {
                Label(model.saved?.useStepData == true ? "Sharing with your Mac" : "Not sharing steps",
                      systemImage: model.saved?.useStepData == true ? "checkmark.circle.fill" : "pause.circle.fill")
                    .foregroundStyle(model.saved?.useStepData == true ? .green : .secondary)
                if let error = model.healthKitError {
                    Text(error).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("What’s shared") {
                Toggle("Step count", isOn: $model.draft.useStepData)
                Toggle("Activity check-ins", isOn: $model.draft.useActivityLog)
                Toggle("On-device insights", isOn: $model.draft.useOnDeviceAI)
            }

            if model.draft != model.saved {
                Button("Save changes") { Task { await model.allow() } }
                    .tint(.orange)
            }

            Section {
                Button("Stop sharing", role: .destructive) { model.stopSharing() }
            } footer: {
                if let date = model.saved?.grantedAt {
                    Text("Last updated \(date.formatted(date: .abbreviated, time: .shortened))")
                }
            }
        }
        .navigationTitle("Step Hub")
    }
}
