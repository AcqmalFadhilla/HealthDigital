//
//  WatchConsentModel.swift
//  HealthDigitalWatch
//

import Foundation
import HealthKit
import Observation

@Observable
@MainActor
final class WatchConsentModel {
    /// Choices on screen (not yet saved).
    var draft: ConsentSettings
    /// What's currently shared with the Mac.
    private(set) var saved: ConsentSettings?
    private(set) var isRequesting = false
    private(set) var healthKitError: String?

    private let sync = ConsentSync()
    private let healthStore = HKHealthStore()

    init() {
        let current = sync.load()
        saved = current
        draft = current ?? ConsentSettings()
        sync.onChange = { [weak self] consent in
            self?.saved = consent
            self?.draft = consent
        }
    }

    var hasConsented: Bool { saved?.hasReviewed == true }

    /// Ask HealthKit for read access to steps (if step data is on), then share the choices with the Mac.
    func allow() async {
        isRequesting = true
        defer { isRequesting = false }
        healthKitError = nil

        if draft.useStepData, HKHealthStore.isHealthDataAvailable() {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: [HKQuantityType(.stepCount)])
            } catch {
                healthKitError = "Couldn’t ask for step access. You can allow it later in Settings › Health."
            }
        }

        var consent = draft
        consent.hasReviewed = true
        consent.grantedOn = "Apple Watch"
        consent.grantedAt = Date()
        sync.save(consent)
        saved = consent
    }

    /// Turns off everything and tells the Mac.
    func stopSharing() {
        var consent = ConsentSettings()
        consent.hasReviewed = true
        consent.useStepData = false
        consent.useActivityLog = false
        consent.useOnDeviceAI = false
        consent.grantedOn = "Apple Watch"
        consent.grantedAt = Date()
        sync.save(consent)
        saved = consent
        draft = consent
    }
}
