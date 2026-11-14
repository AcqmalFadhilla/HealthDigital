//
//  RootView.swift
//  HealthDigital
//
//  Main window after onboarding: Step Hub and History.
//

import SwiftUI

struct RootView: View {
    enum Section: Hashable { case hub, history }
    @State private var selection: Section? = .hub

    var body: some View {
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
