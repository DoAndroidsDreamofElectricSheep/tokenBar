import TokenBarMacroSupport
import Foundation

@ProviderDescriptorRegistration
@ProviderDescriptorDefinition
public enum TraeProviderDescriptor {
    static func makeDescriptor() -> ProviderDescriptor {
        ProviderDescriptor(
            id: .trae,
            metadata: ProviderMetadata(
                id: .trae,
                displayName: "Trae",
                sessionLabel: "Dollar Usage",
                weeklyLabel: "",
                opusLabel: nil,
                supportsOpus: false,
                supportsCredits: false,
                creditsHint: "",
                toggleTitle: "Show Trae usage",
                cliName: "trae",
                defaultEnabled: false,
                isPrimaryProvider: false,
                usesAccountFallback: false,
                dashboardURL: "https://www.trae.ai/account-setting",
                subscriptionDashboardURL: "https://www.trae.ai/account-setting",
                statusPageURL: nil,
                statusLinkURL: "https://www.trae.ai"),
            branding: ProviderBranding(
                iconStyle: .trae,
                iconResourceName: "ProviderIcon-trae",
                color: ProviderColor(red: 0 / 255, green: 229 / 255, blue: 160 / 255)),
            tokenCost: ProviderTokenCostConfig(
                supportsTokenCost: false,
                noDataMessage: { "Trae cost summary is not supported." }),
            fetchPlan: ProviderFetchPlan(
                sourceModes: [.auto],
                pipeline: ProviderFetchPipeline(resolveStrategies: { _ in [TraeLocalStorageFetchStrategy()] })),
            cli: ProviderCLIConfig(
                name: "trae",
                versionDetector: nil))
    }
}

struct TraeLocalStorageFetchStrategy: ProviderFetchStrategy {
    let id: String = "trae.local"
    let kind: ProviderFetchKind = .localProbe

    func isAvailable(_: ProviderFetchContext) async -> Bool {
        TraeUsageProbe.isInstalled()
    }

    func fetch(_: ProviderFetchContext) async throws -> ProviderFetchResult {
        let probe = TraeUsageProbe()
        let snap = try await probe.fetch()
        let usage = try snap.toUsageSnapshot()
        return self.makeResult(usage: usage, sourceLabel: "local")
    }

    func shouldFallback(on _: Error, context _: ProviderFetchContext) -> Bool {
        false
    }
}
