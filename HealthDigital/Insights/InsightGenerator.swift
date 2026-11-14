//
//  InsightGenerator.swift
//  HealthDigital
//
//  Writes the insight under the chart.
//  1. A template insight is always available instantly (and is the fallback).
//  2. If the user allowed on-device AI and Apple Intelligence is available, the
//     Foundation Models framework rewrites it from the same facts.
//  3. The model's text is only shown if every number in it matches the facts and it
//     contains no medical language. Otherwise the template is kept.
//

import Foundation
import FoundationModels

struct Insight: Equatable {
    enum Source: Equatable {
        case onDeviceModel
        case template(reason: String)
    }

    var title: String
    var body: String
    var source: Source
    var generatedAt: Date
    /// Every number in the text appears in the user's data.
    var numbersVerified: Bool
    /// No diagnosis, disease or medication language.
    var noMedicalAdvice: Bool
}

@Generable
nonisolated struct GeneratedInsight {
    @Guide(description: "A short headline of at most 8 words, addressed to the user as 'you'.")
    var title: String
    @Guide(description: "One or two short sentences explaining the headline using only the given facts.")
    var body: String
}

@MainActor
final class InsightGenerator {
    static let instructions = """
    You write short insights for a Mac app that helps office workers reach a daily step goal.
    Rules:
    - Use ONLY the facts provided. Copy numbers and times exactly as written; never calculate, round or invent new ones.
    - Do not guess reasons or causes that are not in the facts.
    - Never give medical advice, never diagnose, never mention diseases, symptoms or medication.
    - Be warm and encouraging, never guilt-tripping. Speak to the user as "you". No emoji.
    - If the user's motivations are given, you may lightly connect to one of them.
    """

    /// Explains why the model isn't being used, or nil if it is available.
    var modelUnavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return "This Mac doesn’t support Apple Intelligence"
            case .appleIntelligenceNotEnabled: return "Apple Intelligence is turned off in System Settings"
            case .modelNotReady: return "Apple Intelligence is still getting ready"
            @unknown default: return "Apple Intelligence isn’t available right now"
            }
        }
    }

    func generate(for facts: InsightFacts, allowAI: Bool) async -> Insight {
        let fallback = template(for: facts, reason: allowAI ? (modelUnavailableReason ?? "") : "On-device AI is off in Settings")
        guard allowAI, modelUnavailableReason == nil, facts.hasData else { return fallback }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let prompt = "Facts:\n" + facts.factLines.map { "- \($0)" }.joined(separator: "\n") + "\n\nWrite the insight."
            let response = try await session.respond(to: prompt, generating: GeneratedInsight.self)
            let text = response.content
            let verified = Self.numbersMatch(text.title + " " + text.body, facts: facts)
            let safe = Self.isFreeOfMedicalLanguage(text.title + " " + text.body)
            guard verified, safe else {
                return template(for: facts, reason: "The AI text didn’t pass the checks, so a template is shown")
            }
            return Insight(title: text.title, body: text.body, source: .onDeviceModel, generatedAt: Date(), numbersVerified: true, noMedicalAdvice: true)
        } catch {
            return template(for: facts, reason: "Apple Intelligence couldn’t write this one")
        }
    }

    // MARK: - Checks

    /// "Every number matches your data": times must be known times, other numbers must be known values.
    static func numbersMatch(_ text: String, facts: InsightFacts) -> Bool {
        var remaining = text
        let timePattern = /\b\d{1,2}:\d{2}\b/
        for match in text.matches(of: timePattern) {
            let time = String(match.output)
            let normalized = time.count == 4 ? "0" + time : time
            guard facts.allowedTimes.contains(normalized) else { return false }
            remaining = remaining.replacingOccurrences(of: time, with: " ")
        }
        let allowed = facts.allowedNumbers
        for match in remaining.matches(of: /\d{1,3}(?:,\d{3})+|\d+/) {
            guard let value = Int(match.output.replacingOccurrences(of: ",", with: "")) else { return false }
            if value <= 3 { continue } // "one walk", "2 floors" style words are harmless
            if !allowed.contains(value) { return false }
        }
        return true
    }

    static func isFreeOfMedicalLanguage(_ text: String) -> Bool {
        let banned = ["diagnos", "disease", "medic", "prescri", "symptom", "treatment", "therapy", "illness", "condition"]
        let lower = text.lowercased()
        return !banned.contains { lower.contains($0) }
    }

    // MARK: - Templates (fallback and instant first paint)

    func template(for f: InsightFacts, reason: String) -> Insight {
        let (title, body) = Self.templateText(for: f)
        return Insight(title: title, body: body, source: .template(reason: reason), generatedAt: Date(), numbersVerified: true, noMedicalAdvice: true)
    }

    static func templateText(for f: InsightFacts) -> (String, String) {
        let projection: String = {
            if f.gap == 0 { return "Goal reached for today." }
            if let t = f.projectedGoalTime { return "At your usual pace you’ll reach \(f.goal.grouped) around \(t)." }
            if let s = f.projectedShortfall { return "At your usual pace you’d end about \(s.grouped) short." }
            return ""
        }()
        let usual: String = {
            guard let u = f.usualByNow else { return "" }
            let diff = f.current - u
            return diff >= 0 ? "That’s \(diff.grouped) ahead of your usual \(u.grouped) by now. " : "Usually you’re at \(u.grouped) by now. "
        }()

        if f.range == .week {
            let title = f.weekGoalDays.map { "\($0) of the last \(f.weekDaysCounted) days reached \(f.goal.grouped)" } ?? "Your week so far"
            let avg = f.weekAverage.map { "You averaged \($0.grouped) steps a day. " } ?? ""
            return (title, "\(avg)Today you’re at \(f.current.grouped).")
        }

        switch f.phase {
        case .completed:
            return ("\(f.activityTitle ?? "Today’s activity") added \(f.activitySteps.grouped) steps",
                    "You’re at \(f.current.grouped), \(f.percent)% of your goal. \(projection)")
        case .inProgress:
            return ("+\(f.activitySteps.grouped) steps since \(f.activityStart ?? "you started") — keep going",
                    "\(f.gap.grouped) left to today’s goal. Tap Done in the menu bar when you finish.")
        case .notified, .waiting:
            if f.gap == 0 {
                return ("You reached your \(f.goal.grouped) goal", "\(usual)Anything from here is a bonus.")
            }
            let window = f.busiestWindow.map { "Most of today’s steps came between \($0.replacingOccurrences(of: "–", with: " and ")). " } ?? ""
            let activity = (f.phase == .notified && f.activityTitle != nil) ? " Today’s activity adds about \(f.activityEstimate?.grouped ?? "")." : ""
            return ("You’re \(f.gap.grouped) steps from today’s goal", "\(usual)\(window)\(projection)\(activity)")
        }
    }
}
