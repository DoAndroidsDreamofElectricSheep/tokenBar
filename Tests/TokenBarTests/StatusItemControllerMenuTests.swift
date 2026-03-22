import TokenBarCore
import Foundation
import Testing
@testable import TokenBar

struct StatusItemControllerMenuTests {
    private func makeSnapshot(primary: RateWindow?, secondary: RateWindow?) -> UsageSnapshot {
        UsageSnapshot(primary: primary, secondary: secondary, updatedAt: Date())
    }
}
