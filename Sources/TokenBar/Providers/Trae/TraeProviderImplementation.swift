import TokenBarCore
import TokenBarMacroSupport
import Foundation

@ProviderImplementationRegistration
struct TraeProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .trae
    let supportsLoginFlow: Bool = false

    @MainActor
    func runLoginFlow(context _: ProviderLoginContext) async -> Bool {
        false
    }
}
