import TokenBarCore
import Foundation
import Testing
@testable import TokenBar

@MainActor
struct ProvidersPaneCoverageTests {
    @Test
    func `exercises providers pane views`() {
        let settings = Self.makeSettingsStore(suite: "ProvidersPaneCoverageTests")
        let store = Self.makeUsageStore(settings: settings)

        ProvidersPaneTestHarness.exercise(settings: settings, store: store)
    }

    @Test
    func `provider detail plan row keeps plan label for non open router`() {
        let row = ProviderDetailView.planRow(provider: .codex, planText: "Pro")

        #expect(row?.label == "Plan")
        #expect(row?.value == "Pro")
    }

    private static func makeSettingsStore(suite: String) -> SettingsStore {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        return SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            codexCookieStore: InMemoryCookieHeaderStore(),
            claudeCookieStore: InMemoryCookieHeaderStore(),
            tokenAccountStore: InMemoryTokenAccountStore())
    }

    private static func makeUsageStore(settings: SettingsStore) -> UsageStore {
        UsageStore(
            fetcher: UsageFetcher(environment: [:]),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings)
    }
}
