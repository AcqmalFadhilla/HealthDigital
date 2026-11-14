//
//  RootView.swift
//  HealthDigital
//

import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    enum Section: Hashable { case hub, history }
    @State private var selection: Section? = .hub

    var body: some View {
        if !model.hasOnboarded {
            OnboardingView()
        } else {
            NavigationSplitView {
                List(selection: $selection) {
                    Label("Step Hub", systemImage: "figure.walk").tag(Section.hub)
                    Label("History", systemImage: "chart.bar").tag(Section.history)
                }
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            } detail: {
                switch selection ?? .hub {
                case .hub: StepHubView()
                case .history: HistoryView()
                }
            }
            .frame(minWidth: 900, minHeight: 640)
        }
    }
}
