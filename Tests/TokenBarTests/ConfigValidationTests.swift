import TokenBarCore
import Foundation
import Testing

struct ConfigValidationTests {
    @Test
    func `reports unsupported source`() {
        var config = TokenBarConfig.makeDefault()
        config.setProviderConfig(ProviderConfig(id: .codex, source: .api))
        let issues = TokenBarConfigValidator.validate(config)
        #expect(issues.contains(where: { $0.code == "unsupported_source" }))
    }

    @Test
    func `warns on unsupported token accounts`() {
        let accounts = ProviderTokenAccountData(
            version: 1,
            accounts: [ProviderTokenAccount(id: UUID(), label: "a", token: "t", addedAt: 0, lastUsed: nil)],
            activeIndex: 0)
        var config = TokenBarConfig.makeDefault()
        config.setProviderConfig(ProviderConfig(id: .gemini, tokenAccounts: accounts))
        let issues = TokenBarConfigValidator.validate(config)
        #expect(issues.contains(where: { $0.code == "token_accounts_unused" }))
    }

}
