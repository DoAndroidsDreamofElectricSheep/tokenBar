import TokenBarCore
import Foundation
import Observation
import Testing
@testable import TokenBar

@MainActor
struct SettingsStoreTests {
    @Test
    func `default refresh frequency is five minutes`() throws {
        let suite = "SettingsStoreTests-default"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        #expect(store.refreshFrequency == .fiveMinutes)
        #expect(store.refreshFrequency.seconds == 300)
    }

    @Test
    func `persists refresh frequency across instances`() throws {
        let suite = "SettingsStoreTests-persist"
        let defaultsA = try #require(UserDefaults(suiteName: suite))
        defaultsA.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let storeA = SettingsStore(
            userDefaults: defaultsA,
            configStore: configStore)

        storeA.refreshFrequency = .fifteenMinutes

        let defaultsB = try #require(UserDefaults(suiteName: suite))
        let storeB = SettingsStore(
            userDefaults: defaultsB,
            configStore: configStore)

        #expect(storeB.refreshFrequency == .fifteenMinutes)
        #expect(storeB.refreshFrequency.seconds == 900)
    }

    @Test
    func `persists selected menu provider across instances`() throws {
        let suite = "SettingsStoreTests-selectedMenuProvider"
        let defaultsA = try #require(UserDefaults(suiteName: suite))
        defaultsA.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let storeA = SettingsStore(
            userDefaults: defaultsA,
            configStore: configStore)

        storeA.selectedMenuProvider = .claude

        let defaultsB = try #require(UserDefaults(suiteName: suite))
        let storeB = SettingsStore(
            userDefaults: defaultsB,
            configStore: configStore)

        #expect(storeB.selectedMenuProvider == .claude)
    }

    @Test
    func `persists merged menu last selected was overview across instances`() throws {
        let suite = "SettingsStoreTests-merged-last-overview"
        let defaultsA = try #require(UserDefaults(suiteName: suite))
        defaultsA.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let storeA = SettingsStore(
            userDefaults: defaultsA,
            configStore: configStore)

        storeA.mergedMenuLastSelectedWasOverview = true

        let defaultsB = try #require(UserDefaults(suiteName: suite))
        let storeB = SettingsStore(
            userDefaults: defaultsB,
            configStore: configStore)

        #expect(storeB.mergedMenuLastSelectedWasOverview == true)
    }

    @Test
    func `merged overview selected providers persists and normalizes across instances`() throws {
        let suite = "SettingsStoreTests-merged-overview-selection"
        let defaultsA = try #require(UserDefaults(suiteName: suite))
        defaultsA.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let storeA = SettingsStore(
            userDefaults: defaultsA,
            configStore: configStore)

        storeA.mergedOverviewSelectedProviders = [.gemini, .codex, .gemini, .claude]
        #expect(storeA.mergedOverviewSelectedProviders == [.gemini, .codex, .claude])

        let defaultsB = try #require(UserDefaults(suiteName: suite))
        let storeB = SettingsStore(
            userDefaults: defaultsB,
            configStore: configStore)

        #expect(storeB.mergedOverviewSelectedProviders == [.gemini, .codex, .claude])
    }

    @Test
    func `merged overview selected providers ignores invalid raw values`() throws {
        let suite = "SettingsStoreTests-merged-overview-invalid-raw"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defaults.set(["codex", "unknown-provider", "claude", "codex"], forKey: "mergedOverviewSelectedProviders")
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        #expect(store.mergedOverviewSelectedProviders == [.codex, .claude])
    }

    @Test
    func `resolved merged overview providers defaults to first three when selection empty`() throws {
        let suite = "SettingsStoreTests-merged-overview-default-first-three"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini, .antigravity]
        let resolved = store.resolvedMergedOverviewProviders(activeProviders: activeProviders)

        #expect(resolved == [.codex, .claude, .gemini])
    }

    @Test
    func `resolved merged overview providers honors explicit empty selection`() throws {
        let suite = "SettingsStoreTests-merged-overview-explicit-empty"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        store.mergedOverviewSelectedProviders = []
        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini, .antigravity]
        let resolved = store.resolvedMergedOverviewProviders(activeProviders: activeProviders)

        #expect(resolved == [])
    }

    @Test
    func `resolved merged overview providers uses provider order not selection order`() throws {
        let suite = "SettingsStoreTests-merged-overview-order"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        store.mergedOverviewSelectedProviders = [.antigravity, .codex, .gemini]
        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini, .antigravity]
        let resolved = store.resolvedMergedOverviewProviders(activeProviders: activeProviders)

        #expect(resolved == [.codex, .gemini, .antigravity])
    }

    @Test
    func `reconcile merged overview selection removes unavailable without auto fill`() throws {
        let suite = "SettingsStoreTests-merged-overview-reconcile"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        store.mergedOverviewSelectedProviders = [.codex, .claude, .antigravity]
        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini, .antigravity]

        let resolved = store.reconcileMergedOverviewSelectedProviders(activeProviders: activeProviders)

        #expect(resolved == [.codex, .claude, .antigravity])
        #expect(store.mergedOverviewSelectedProviders == [.codex, .claude, .antigravity])
    }

    @Test
    func `reconcile merged overview selection does not clobber stored preference when three or fewer`() throws {
        let suite = "SettingsStoreTests-merged-overview-three-or-fewer"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        store.mergedOverviewSelectedProviders = [.codex, .claude, .gemini]
        let activeProviders: [UsageProvider] = [.codex, .claude]

        let resolved = store.reconcileMergedOverviewSelectedProviders(activeProviders: activeProviders)

        #expect(resolved == [.codex, .claude])
        #expect(store.mergedOverviewSelectedProviders == [.codex, .claude, .gemini])
    }

    @Test
    func `reconcile merged overview selection ignores stale subset without persisting auto fill when three or fewer`()
        throws
    {
        let suite = "SettingsStoreTests-merged-overview-three-or-fewer-subset"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        store.mergedOverviewSelectedProviders = [.codex]
        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini]

        let resolved = store.reconcileMergedOverviewSelectedProviders(activeProviders: activeProviders)

        #expect(resolved == [.codex, .claude, .gemini])
        #expect(store.mergedOverviewSelectedProviders == [.codex])
    }

    @Test
    func `merged overview selection allows deselecting providers when three or fewer`() throws {
        let suite = "SettingsStoreTests-merged-overview-deselect-three-or-fewer"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini]
        #expect(store.resolvedMergedOverviewProviders(activeProviders: activeProviders) == activeProviders)

        _ = store.setMergedOverviewProviderSelection(
            provider: .claude,
            isSelected: false,
            activeProviders: activeProviders)

        #expect(store.mergedOverviewSelectedProviders == [.codex, .gemini])
        #expect(store.resolvedMergedOverviewProviders(activeProviders: activeProviders) == [.codex, .gemini])
    }

    @Test
    func `merged overview selection applies when same active set is reordered`() throws {
        let suite = "SettingsStoreTests-merged-overview-ordered-context"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        let initialActiveProviders: [UsageProvider] = [.codex, .claude, .gemini]
        _ = store.setMergedOverviewProviderSelection(
            provider: .claude,
            isSelected: false,
            activeProviders: initialActiveProviders)

        let reorderedActiveProviders: [UsageProvider] = [.gemini, .codex, .claude]
        let resolved = store.resolvedMergedOverviewProviders(activeProviders: reorderedActiveProviders)

        #expect(resolved == [.gemini, .codex])
    }

    @Test
    func `merged overview selection allows deselecting providers when more than three active`() throws {
        let suite = "SettingsStoreTests-merged-overview-deselect-subset"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        store.mergedOverviewSelectedProviders = [.codex, .claude, .gemini]
        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini, .antigravity]

        _ = store.setMergedOverviewProviderSelection(
            provider: .gemini,
            isSelected: false,
            activeProviders: activeProviders)

        #expect(store.mergedOverviewSelectedProviders == [.codex, .claude])
        #expect(store.resolvedMergedOverviewProviders(activeProviders: activeProviders) == [.codex, .claude])
    }

    @Test
    func `reconcile merged overview selection preserves stored subset when active drops to three or fewer`() throws {
        let suite = "SettingsStoreTests-merged-overview-preserve-subset-across-drop"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini, .antigravity]
        _ = store.setMergedOverviewProviderSelection(
            provider: .claude,
            isSelected: false,
            activeProviders: activeProviders)
        _ = store.setMergedOverviewProviderSelection(
            provider: .antigravity,
            isSelected: true,
            activeProviders: activeProviders)
        #expect(store.mergedOverviewSelectedProviders == [.codex, .gemini, .antigravity])

        let reducedActiveProviders: [UsageProvider] = [.codex, .claude, .gemini]
        let resolvedWhenReduced = store.reconcileMergedOverviewSelectedProviders(
            activeProviders: reducedActiveProviders)

        #expect(resolvedWhenReduced == [.codex, .claude, .gemini])
        #expect(store.mergedOverviewSelectedProviders == [.codex, .gemini, .antigravity])

        let resolvedWhenRestored = store.resolvedMergedOverviewProviders(activeProviders: activeProviders)
        #expect(resolvedWhenRestored == [.codex, .gemini, .antigravity])
    }

    @Test
    func `reconcile merged overview selection clears preference when no providers active`() throws {
        let suite = "SettingsStoreTests-merged-overview-clear-on-empty-active"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        let activeProviders: [UsageProvider] = [.codex, .claude, .gemini, .antigravity]
        _ = store.setMergedOverviewProviderSelection(
            provider: .codex,
            isSelected: false,
            activeProviders: activeProviders)
        #expect(store.resolvedMergedOverviewProviders(activeProviders: activeProviders) == [.claude, .gemini])

        let resolvedWhenEmpty = store.reconcileMergedOverviewSelectedProviders(activeProviders: [])
        #expect(resolvedWhenEmpty == [])

        let resolvedAfterReenable = store.resolvedMergedOverviewProviders(activeProviders: activeProviders)
        #expect(resolvedAfterReenable == [.codex, .claude, .gemini])
    }

    @Test
    func `defaults session quota notifications to enabled`() throws {
        let key = "sessionQuotaNotificationsEnabled"
        let suite = "SettingsStoreTests-sessionQuotaNotifications"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)
        #expect(store.sessionQuotaNotificationsEnabled == true)
        #expect(defaults.bool(forKey: key) == true)
    }

    @Test
    func `defaults claude usage source to auto`() throws {
        let suite = "SettingsStoreTests-claude-source"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        #expect(store.claudeUsageDataSource == .auto)
    }

    @Test
    func `defaults codex usage source to auto`() throws {
        let suite = "SettingsStoreTests-codex-source"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        #expect(store.codexUsageDataSource == .auto)
    }

    @Test
    @MainActor
    func `apply external config does not broadcast`() throws {
        let suite = "SettingsStoreTests-external-config"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        final class NotificationCounter: @unchecked Sendable {
            private let lock = NSLock()
            private var value = 0

            func increment() {
                self.lock.lock()
                self.value += 1
                self.lock.unlock()
            }

            func get() -> Int {
                self.lock.lock()
                defer { self.lock.unlock() }
                return self.value
            }
        }

        let notifications = NotificationCounter()
        let token = NotificationCenter.default.addObserver(
            forName: .tokenbarProviderConfigDidChange,
            object: store,
            queue: .main)
        { _ in
            notifications.increment()
        }
        defer { NotificationCenter.default.removeObserver(token) }

        store.applyExternalConfig(store.configSnapshot, reason: "test-external")

        #expect(notifications.get() == 0)
    }

    @Test
    func `defaults open AI web access to enabled`() throws {
        let suite = "SettingsStoreTests-openai-web"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defaults.set(false, forKey: "debugDisableKeychainAccess")
        let configStore = testConfigStore(suiteName: suite)

        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        #expect(store.openAIWebAccessEnabled == true)
        #expect(defaults.bool(forKey: "openAIWebAccessEnabled") == true)
        #expect(store.codexCookieSource == .auto)
    }

    @Test
    func `menu observation token updates on defaults change`() async throws {
        let suite = "SettingsStoreTests-observation-defaults"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        var didChange = false

        withObservationTracking {
            _ = store.menuObservationToken
        } onChange: {
            Task { @MainActor in
                didChange = true
            }
        }

        store.statusChecksEnabled.toggle()
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(didChange == true)
    }

    @Test
    func `config backed settings trigger observation`() async throws {
        let suite = "SettingsStoreTests-observation-config"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        var didChange = false

        withObservationTracking {
            _ = store.codexCookieSource
        } onChange: {
            Task { @MainActor in
                didChange = true
            }
        }

        store.codexCookieSource = .manual
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(didChange == true)
    }

    @Test
    func `provider order defaults to all cases`() throws {
        let suite = "SettingsStoreTests-providerOrder-default"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        let store = SettingsStore(
            userDefaults: defaults,
            configStore: configStore)

        #expect(store.orderedProviders() == UsageProvider.allCases)
    }

    @Test
    func `provider order persists and appends new providers`() throws {
        let suite = "SettingsStoreTests-providerOrder-persist"
        let defaultsA = try #require(UserDefaults(suiteName: suite))
        defaultsA.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        // Partial list to mimic "older version" missing providers.
        let config = TokenBarConfig(providers: [
            ProviderConfig(id: .gemini),
            ProviderConfig(id: .codex),
        ])
        try configStore.save(config)

        let storeA = SettingsStore(
            userDefaults: defaultsA,
            configStore: configStore)

        #expect(storeA.orderedProviders() == [
            .gemini,
            .codex,
            .claude,
            .antigravity,
        ])

        // Move one provider; ensure it's persisted across instances.
        let antigravityIndex = try #require(storeA.orderedProviders().firstIndex(of: .antigravity))
        storeA.moveProvider(fromOffsets: IndexSet(integer: antigravityIndex), toOffset: 0)

        let defaultsB = try #require(UserDefaults(suiteName: suite))
        let storeB = SettingsStore(
            userDefaults: defaultsB,
            configStore: configStore)

        #expect(storeB.orderedProviders().first == .antigravity)
    }
}
