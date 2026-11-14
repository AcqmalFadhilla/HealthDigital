//
//  AppModel.swift
//  HealthDigital
//
//  Single source of truth shared by the main window, the menu bar extra and Settings.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class AppModel {
    // MARK: Stored state

    var profile: UserProfile {
        didSet {
            guard profile != oldValue else { return }
            Persistence.save(profile)
            rescheduleReminders()
            recompute()
        }
    }

    var consent: ConsentSettings {
        didSet {
            guard consent != oldValue else { return }
            Persistence.save(consent)
            Task { await refresh(forceInsight: true) }
        }
    }

    var hasOnboarded: Bool {
        didSet { Persistence.hasOnboarded = hasOnboarded }
    }

    var session: ActivitySession {
        didSet { Persistence.save(session) }
    }

    var range: ChartRange = .day {
        didSet { recompute() }
    }

    private(set) var snapshot: StepSnapshot = .empty
    private(set) var facts: InsightFacts?
    private(set) var insight: Insight?
    private(set) var isWritingInsight = false
    private(set) var now = Date()
    /// Steps credited to today's activity (live while in progress).
    private(set) var activitySteps = 0

    // MARK: Dependencies

    let dataSource: StepDataSource
    let generator = InsightGenerator()
    let scheduler = ReminderScheduler()
    /// Consent is given on Apple Watch and arrives here through iCloud.
    let consentSync = ConsentSync()

    private var tickTimer: Timer?
    private var lastInsightKey: String?
    private var insightTask: Task<Void, Never>?

    init(dataSource: StepDataSource? = nil) {
        let dataSource = dataSource ?? SampleStepDataSource()
        self.dataSource = dataSource
        self.profile = Persistence.loadProfile()
        self.consent = consentSync.load() ?? Persistence.loadConsent()
        self.hasOnboarded = Persistence.hasOnboarded
        let saved = Persistence.loadSession()
        self.session = (saved?.dayKey == ActivitySession.key(for: Date())) ? saved! : .fresh(for: Date())

        dataSource.onUpdate = { [weak self] in
            Task { await self?.refresh() }
        }
        consentSync.onChange = { [weak self] consent in
            self?.consent = consent
        }
        scheduler.configure()
        scheduler.onStart = { [weak self] in self?.startActivity() }
        scheduler.onFire = { [weak self] in self?.checkReminder() }

        tickTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                Task { await self.refresh() }
            }
        }
        if session.phase == .inProgress { sample?.setSimulatedWalking(true) }
        rescheduleReminders()
        Task { await refresh() }
    }

    // MARK: Derived

    var todayActivity: StepActivity? {
        StepActivity.activity(for: now, from: profile.activities, offset: session.activityOffset)
    }

    var currentSteps: Int { snapshot.todayTotal }
    var gap: Int { max(profile.dailyGoal - currentSteps, 0) }
    var progress: Double { profile.dailyGoal > 0 ? min(Double(currentSteps) / Double(profile.dailyGoal), 1) : 0 }

    /// Red dot in the menu bar: the reminder fired and the user hasn't acted yet.
    var needsAttention: Bool { session.phase == .notified }

    var isReminderDay: Bool { profile.reminder.isActive(on: now) }

    var reminderStatusText: String {
        guard profile.reminder.isEnabled else { return "Reminder is off" }
        switch session.phase {
        case .waiting:
            return isReminderDay ? "Today’s activity at \(profile.reminder.timeLabel)" : "No reminder today"
        case .notified: return "Today’s activity is ready"
        case .inProgress: return "In progress: \(todayActivity?.title ?? "activity")"
        case .completed: return "Today’s activity done"
        }
    }

    private var sample: SampleStepDataSource? { dataSource as? SampleStepDataSource }

    /// Consent hasn't been given on Apple Watch yet.
    var awaitingWatchConsent: Bool { !consent.hasReviewed }
    var canUseSteps: Bool { consent.hasReviewed && consent.useStepData }
    var canUseAI: Bool { consent.hasReviewed && consent.useOnDeviceAI }

    // MARK: Refresh

    func refresh(forceInsight: Bool = false) async {
        now = Date()
        rolloverIfNeeded()
        checkReminder()

        if canUseSteps {
            snapshot = await dataSource.snapshot(now: now)
        } else {
            snapshot = .empty
        }

        switch session.phase {
        case .inProgress:
            if let start = session.startedAt, consent.useActivityLog {
                activitySteps = await dataSource.steps(from: start, to: now)
            }
        case .completed:
            activitySteps = session.creditedSteps
        default:
            activitySteps = 0
        }
        recompute(forceInsight: forceInsight)
    }

    private func recompute(forceInsight: Bool = false) {
        let newFacts = InsightFacts.make(snapshot: snapshot, profile: profile, session: session,
                                         activity: todayActivity, activitySteps: activitySteps,
                                         range: range, now: now)
        facts = newFacts
        updateInsight(for: newFacts, force: forceInsight)
    }

    /// Numbers are live on every sync. The wording is only regenerated when the kind of
    /// message changes (phase, goal reached, range, every 15 min) or when the current text
    /// no longer matches the latest numbers.
    private func updateInsight(for facts: InsightFacts, force: Bool) {
        let allowAI = canUseAI
        let key = facts.regenerationKey + "|\(allowAI)"
        var stale = false
        if let insight, insight.source == .onDeviceModel {
            stale = !InsightGenerator.numbersMatch(insight.title + " " + insight.body, facts: facts)
        }

        if force || key != lastInsightKey || stale {
            lastInsightKey = key
            insight = generator.template(for: facts, reason: allowAI ? "Writing with Apple Intelligence…" : "On-device insights are off on your Apple Watch")
            insightTask?.cancel()
            guard allowAI, facts.hasData, facts.phase != .inProgress else {
                if allowAI, let reason = generator.modelUnavailableReason { insight = generator.template(for: facts, reason: reason) }
                isWritingInsight = false
                return
            }
            isWritingInsight = true
            insightTask = Task { [weak self] in
                guard let self else { return }
                let result = await self.generator.generate(for: facts, allowAI: true)
                guard !Task.isCancelled, self.lastInsightKey == key else { return }
                self.insight = result
                self.isWritingInsight = false
            }
        } else if case .template = insight?.source {
            // Template text: just refresh the numbers in place.
            insight = generator.template(for: facts, reason: templateReason)
        }
    }

    private var templateReason: String {
        if case .template(let reason) = insight?.source { return reason }
        return ""
    }

    // MARK: Daily reminder flow

    func checkReminder() {
        guard session.phase == .waiting, profile.reminder.isActive(on: now),
              now >= profile.reminder.fireDate(on: now) else { return }
        session.phase = .notified
    }

    /// "Yes, I'm doing it now"
    func startActivity() {
        guard session.phase == .notified || session.phase == .waiting else { return }
        session.phase = .inProgress
        session.startedAt = Date()
        session.creditedSteps = 0
        activitySteps = 0
        sample?.setSimulatedWalking(true)
        rescheduleReminders()
        Task { await refresh(forceInsight: true) }
    }

    /// "Done": credit the Watch steps counted since start, then refresh chart + insight.
    func finishActivity() {
        guard session.phase == .inProgress else { return }
        sample?.setSimulatedWalking(false)
        Task {
            let end = Date()
            var credited = 0
            if let start = session.startedAt {
                credited = await dataSource.steps(from: start, to: end)
            }
            session.phase = .completed
            session.completedAt = end
            session.creditedSteps = credited
            await refresh(forceInsight: true)
        }
    }

    func cancelActivity() {
        guard session.phase == .inProgress else { return }
        sample?.setSimulatedWalking(false)
        session.phase = .notified
        session.startedAt = nil
        Task { await refresh(forceInsight: true) }
    }

    /// "Different activity": rotate to the next picked activity, today only.
    func swapActivity() {
        session.activityOffset += 1
        rescheduleReminders()
        recompute(forceInsight: true)
    }

    func completeOnboarding() {
        hasOnboarded = true
        Task {
            if profile.reminder.isEnabled { await scheduler.requestAuthorization() }
            rescheduleReminders()
            await refresh(forceInsight: true)
        }
    }

    private func rolloverIfNeeded() {
        let key = ActivitySession.key(for: now)
        guard session.dayKey != key else { return }
        sample?.setSimulatedWalking(false)
        session = .fresh(for: now)
        rescheduleReminders()
    }

    func rescheduleReminders() {
        scheduler.reschedule(profile: profile, session: session, now: Date())
    }

    // MARK: Developer helpers (Settings › Developer)

    var sampleScenario: SampleScenario? {
        get { sample?.scenario }
        set { if let newValue { sample?.scenario = newValue } }
    }

    /// Pretend the user tapped Allow on the Watch (for testing without a paired Watch).
    func simulateWatchConsent() {
        var c = ConsentSettings()
        c.hasReviewed = true
        c.grantedOn = "Apple Watch (simulated)"
        c.grantedAt = Date()
        consentSync.save(c)
        consent = c
    }

    func triggerReminderNow() {
        sample?.setSimulatedWalking(false)
        var fresh = ActivitySession.fresh(for: Date())
        fresh.phase = .notified
        fresh.activityOffset = session.activityOffset
        session = fresh
        Task { await refresh(forceInsight: true) }
    }

    func resetToday() {
        sample?.setSimulatedWalking(false)
        session = .fresh(for: Date())
        rescheduleReminders()
        Task { await refresh(forceInsight: true) }
    }

    func resetOnboarding() {
        Persistence.reset()
        profile = UserProfile()
        consent = ConsentSettings()
        session = .fresh(for: Date())
        hasOnboarded = false
    }
}
