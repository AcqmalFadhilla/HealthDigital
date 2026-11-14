//
//  HistoryView.swift
//  HealthDigital
//

import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let goal = model.profile.dailyGoal
        Group {
            if model.snapshot.history.isEmpty {
                ContentUnavailableView("No history yet", systemImage: "calendar",
                                       description: Text("Past days appear here once your Watch has synced them."))
            } else {
                List(model.snapshot.history.reversed()) { day in
                    HStack {
                        Text(day.date.formatted(.dateTime.weekday(.wide).day().month()))
                        Spacer()
                        Text(day.total.grouped).monospacedDigit()
                        Image(systemName: day.total >= goal ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(day.total >= goal ? .green : .secondary)
                            .accessibilityLabel(day.total >= goal ? "Goal reached" : "Goal not reached")
                    }
                }
            }
        }
        .navigationTitle("History")
    }
}
