import Foundation

public enum ProviderConfigEnvironment {
    public static func applyAPIKeyOverride(
        base: [String: String],
        provider: UsageProvider,
        config: ProviderConfig?) -> [String: String]
    {
        guard let apiKey = config?.sanitizedAPIKey, !apiKey.isEmpty else { return base }
        // No remaining providers require API key environment overrides.
        // The apiKey is still available in config for providers that read it directly.
        _ = apiKey
        _ = provider
        return base
    }
}
