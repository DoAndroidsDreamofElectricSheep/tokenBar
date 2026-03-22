import TokenBarCore
import Foundation
import Testing
@testable import TokenBar

@MainActor
struct UsageStoreSessionQuotaTransitionTests {
    @MainActor
    final class SessionQuotaNotifierSpy: SessionQuotaNotifying {
        private(set) var posts: [(transition: SessionQuotaTransition, provider: UsageProvider)] = []

        func post(transition: SessionQuotaTransition, provider: UsageProvider, badge _: NSNumber?) {
            self.posts.append((transition: transition, provider: provider))
        }
    }
}
