//
//  HealthDigitalWatchApp.swift
//  HealthDigitalWatch
//
//  The Watch side of Step Hub. For now it owns consent: what is shared, why, and where it
//  stays. Step counting/sync is owned by the Watch data integration.
//

import SwiftUI

@main
struct HealthDigitalWatchApp: App {
    @State private var model = WatchConsentModel()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(model)
        }
    }
}
