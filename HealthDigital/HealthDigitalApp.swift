//
//  HealthDigitalApp.swift
//  HealthDigital
//
//  Created by acqmal on 11/14/26.
//

import SwiftUI

@main
struct HealthDigitalApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("Step Hub", id: "main") {
            RootView()
                .environment(model)
        }
        .defaultSize(width: 1100, height: 780)

        MenuBarExtra {
            MenuBarView()
                .environment(model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
