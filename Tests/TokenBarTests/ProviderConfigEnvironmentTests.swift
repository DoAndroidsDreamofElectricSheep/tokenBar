import TokenBarCore
import Testing

struct ProviderConfigEnvironmentTests {
    @Test
    func `leaves environment when API key missing`() {
        let config = ProviderConfig(id: .codex, apiKey: nil)
        let env = ProviderConfigEnvironment.applyAPIKeyOverride(
            base: ["EXISTING_KEY": "existing"],
            provider: .codex,
            config: config)

        #expect(env["EXISTING_KEY"] == "existing")
    }
}
