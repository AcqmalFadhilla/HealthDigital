//
//  Persistence.swift
//  HealthDigital
//
//  Small, local-only storage for Step Hub state. The user's profile is stored by
//  OnboardingPersistence (Onboarding/OnboardingProfile.swift). Nothing here leaves the Mac.
//

import Foundation

enum Persistence {
    private enum Key {
        static let consent = "consent.v1"
        static let session = "session.v1"
    }

    private static let defaults = UserDefaults.standard

    /// Local cache of the consent given on Apple Watch.
    static func loadConsent() -> ConsentSettings { load(Key.consent) ?? ConsentSettings() }
    static func save(_ consent: ConsentSettings) { save(consent, Key.consent) }

    static func loadSession() -> ActivitySession? { load(Key.session) }
    static func save(_ session: ActivitySession) { save(session, Key.session) }

    /// Clears Step Hub state, used by "Reset onboarding" in Settings › Developer.
    static func reset() {
        [Key.consent, Key.session].forEach(defaults.removeObject(forKey:))
    }

    private static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, _ key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
