import Foundation

extension TokenAccountSupportCatalog {
    static let supportByProvider: [UsageProvider: TokenAccountSupport] = [
        .claude: TokenAccountSupport(
            title: "Session tokens",
            subtitle: "Store Claude sessionKey cookies or OAuth access tokens.",
            placeholder: "Paste sessionKey or OAuth token…",
            injection: .cookieHeader,
            requiresManualCookieSource: true,
            cookieName: "sessionKey"),
    ]
}
