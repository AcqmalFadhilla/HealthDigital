//
//  Consent.swift
//  Shared by the Mac app and the Watch app.
//
//  Consent is given on Apple Watch (what, why, where) and synced to the Mac through the
//  iCloud key-value store, so both devices always agree on what may be used.
//

import Foundation

/// What the user agreed to on the Watch consent screen.
struct ConsentSettings: Codable, Equatable {
    var hasReviewed = false
    /// Step count from Apple Watch. Required for the hub to show progress.
    var useStepData = true
    /// Start/finish times of the daily activity, used to credit its steps.
    var useActivityLog = true
    /// Let Apple's on-device model on the Mac write insight sentences. Off → template text.
    var useOnDeviceAI = true
    /// Where and when consent was last given, e.g. "Apple Watch".
    var grantedOn: String?
    var grantedAt: Date?
}

/// Reads and writes consent in the iCloud key-value store shared by both apps.
@MainActor
final class ConsentSync {
    static let key = "consent.v1"

    /// Called when consent changes on another device.
    var onChange: ((ConsentSettings) -> Void)?

    private let store = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let consent = self.load() else { return }
                self.onChange?(consent)
            }
        }
        store.synchronize()
    }

    func load() -> ConsentSettings? {
        guard let data = store.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(ConsentSettings.self, from: data)
    }

    func save(_ consent: ConsentSettings) {
        guard let data = try? JSONEncoder().encode(consent) else { return }
        store.set(data, forKey: Self.key)
        store.synchronize()
    }
}
