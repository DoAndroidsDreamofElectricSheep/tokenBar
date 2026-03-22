import AppKit
import TokenBarCore
import Testing
@testable import TokenBar

@MainActor
struct AppDelegateTests {
    @Test
    func `builds status controller after launch`() {
        let appDelegate = AppDelegate()
        var factoryCalls = 0

        // Install a test factory that records invocations without touching NSStatusBar.
        StatusItemController.factory = { _, _, _, _, _ in
            factoryCalls += 1
            return DummyStatusController()
        }
        defer { StatusItemController.factory = StatusItemController.defaultFactory }

        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "AppDelegateTests"))
        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        let account = fetcher.loadAccountInfo()

        // configure should not eagerly construct the status controller
        appDelegate.configure(store: store, settings: settings, account: account, selection: PreferencesSelection())
        #expect(factoryCalls == 0)

        // construction happens once after launch
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        #expect(factoryCalls == 1)

        // idempotent on subsequent calls
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        #expect(factoryCalls == 1)
    }
}

@MainActor
private final class DummyStatusController: StatusItemControlling {
    func openMenuFromShortcut() {}
}
