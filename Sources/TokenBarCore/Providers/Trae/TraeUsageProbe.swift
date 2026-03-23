import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Errors

public enum TraeUsageProbeError: LocalizedError, Sendable, Equatable {
    case notInstalled
    case tokenExpired
    case noSubscriptionFound
    case apiError(String)
    case parseFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            "Trae is not installed or has never been launched."
        case .tokenExpired:
            "Trae session expired. Open Trae to refresh your login."
        case .noSubscriptionFound:
            "No active Trae subscription found."
        case let .apiError(message):
            "Trae API error: \(message)"
        case let .parseFailed(message):
            "Could not parse Trae response: \(message)"
        }
    }
}

// MARK: - Auth

struct TraeAuthInfo: Sendable {
    let token: String
    let host: String
    let username: String?
}

// MARK: - Response models

private struct TraeEntitlementResponse: Decodable {
    let isDollarUsageBilling: Bool?
    let isPayFreshman: Bool?
    let userEntitlementPackList: [TraeEntitlementPack]?

    enum CodingKeys: String, CodingKey {
        case isDollarUsageBilling = "is_dollar_usage_billing"
        case isPayFreshman = "is_pay_freshman"
        case userEntitlementPackList = "user_entitlement_pack_list"
    }
}

private struct TraeEntitlementPack: Decodable {
    let entitlementBaseInfo: TraeEntitlementBaseInfo?
    let usage: TraeUsage?
    let status: Int?
    let nextBillingTime: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case entitlementBaseInfo = "entitlement_base_info"
        case usage
        case status
        case nextBillingTime = "next_billing_time"
    }
}

private struct TraeEntitlementBaseInfo: Decodable {
    let productType: Int?
    let endTime: TimeInterval?
    let quota: TraeQuota?
    let userId: String?

    enum CodingKeys: String, CodingKey {
        case productType = "product_type"
        case endTime = "end_time"
        case quota
        case userId = "user_id"
    }
}

private struct TraeQuota: Decodable {
    let basicUsageLimit: Double?
    let premiumModelFastRequestLimit: Int?
    let premiumModelSlowRequestLimit: Int?

    enum CodingKeys: String, CodingKey {
        case basicUsageLimit = "basic_usage_limit"
        case premiumModelFastRequestLimit = "premium_model_fast_request_limit"
        case premiumModelSlowRequestLimit = "premium_model_slow_request_limit"
    }
}

private struct TraeUsage: Decodable {
    let basicUsageAmount: Double?
    let isFlashConsuming: Bool?

    enum CodingKeys: String, CodingKey {
        case basicUsageAmount = "basic_usage_amount"
        case isFlashConsuming = "is_flash_consuming"
    }
}

// MARK: - Snapshot

public struct TraeUsageSnapshot: Sendable {
    public let usedDollars: Double
    public let limitDollars: Double
    public let resetsAt: Date?
    public let username: String?
    public let planName: String

    public func toUsageSnapshot() throws -> UsageSnapshot {
        guard self.limitDollars > 0 else {
            throw TraeUsageProbeError.noSubscriptionFound
        }
        let usedPercent = min(100, (self.usedDollars / self.limitDollars) * 100)
        let primary = RateWindow(
            usedPercent: usedPercent,
            windowMinutes: nil,
            resetsAt: self.resetsAt,
            resetDescription: nil)
        let identity = ProviderIdentitySnapshot(
            providerID: .trae,
            accountEmail: self.username,
            accountOrganization: nil,
            loginMethod: self.planName)
        return UsageSnapshot(
            primary: primary,
            secondary: nil,
            tertiary: nil,
            updatedAt: Date(),
            identity: identity)
    }
}

// MARK: - Probe

public struct TraeUsageProbe: Sendable {
    public var timeout: TimeInterval = 10.0

    private static let storagePath =
        ("~/Library/Application Support/Trae/User/globalStorage/storage.json" as NSString)
        .expandingTildeInPath

    private static let entitlementEndpoint = "/trae/api/v1/pay/user_current_entitlement_list"
    private static let log = TokenBarLog.logger(LogCategories.trae)

    public init(timeout: TimeInterval = 10.0) {
        self.timeout = timeout
    }

    public static func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: self.storagePath)
    }

    public func fetch() async throws -> TraeUsageSnapshot {
        let auth = try Self.readAuth()
        Self.log.debug("Auth loaded", metadata: ["user": auth.username ?? "unknown", "host": auth.host])
        let data = try await self.callAPI(auth: auth)
        let snapshot = try Self.parseResponse(data: data, username: auth.username)
        Self.log.info(
            "Trae usage fetched",
            metadata: [
                "used": String(format: "%.2f", snapshot.usedDollars),
                "limit": String(format: "%.0f", snapshot.limitDollars),
                "plan": snapshot.planName,
            ])
        return snapshot
    }

    // MARK: - Auth

    static func readAuth() throws -> TraeAuthInfo {
        guard FileManager.default.fileExists(atPath: self.storagePath) else {
            throw TraeUsageProbeError.notInstalled
        }

        let raw = try Data(contentsOf: URL(fileURLWithPath: self.storagePath))
        guard let json = try JSONSerialization.jsonObject(with: raw) as? [String: Any],
              let authRaw = json["iCubeAuthInfo://icube.cloudide"] as? String,
              let authData = authRaw.data(using: .utf8),
              let authJSON = try JSONSerialization.jsonObject(with: authData) as? [String: Any]
        else {
            throw TraeUsageProbeError.notInstalled
        }

        guard let token = authJSON["token"] as? String, !token.isEmpty else {
            throw TraeUsageProbeError.tokenExpired
        }

        let host = authJSON["host"] as? String ?? "https://api-sg-central.trae.ai"
        let account = authJSON["account"] as? [String: Any]
        let username = account?["username"] as? String

        // Verify token not expired
        if let expiredAt = authJSON["expiredAt"] as? String,
           let expDate = ISO8601DateFormatter().date(from: expiredAt),
           expDate < Date()
        {
            throw TraeUsageProbeError.tokenExpired
        }

        return TraeAuthInfo(token: token, host: host, username: username)
    }

    // MARK: - API

    private func callAPI(auth: TraeAuthInfo) async throws -> Data {
        let urlString = auth.host + Self.entitlementEndpoint
        guard let url = URL(string: urlString) else {
            throw TraeUsageProbeError.apiError("Invalid URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = self.timeout
        request.setValue("Cloud-IDE-JWT \(auth.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("TraeMonitor/1.1", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.trae.ai", forHTTPHeaderField: "Origin")
        request.setValue("https://www.trae.ai/", forHTTPHeaderField: "Referer")

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = self.timeout
        config.timeoutIntervalForResource = self.timeout
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }

        Self.log.debug("Fetching Trae usage", metadata: ["host": auth.host])
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TraeUsageProbeError.apiError("Invalid response")
        }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw TraeUsageProbeError.tokenExpired
            }
            throw TraeUsageProbeError.apiError("HTTP \(http.statusCode)")
        }
        return data
    }

    // MARK: - Parsing

    static func parseResponse(data: Data, username: String?) throws -> TraeUsageSnapshot {
        let decoder = JSONDecoder()
        let response = try decoder.decode(TraeEntitlementResponse.self, from: data)

        let packs = response.userEntitlementPackList ?? []

        // Find the active subscription pack (product_type == 1)
        guard let subscriptionPack = packs.first(where: {
            $0.entitlementBaseInfo?.productType == 1
        }) else {
            throw TraeUsageProbeError.noSubscriptionFound
        }

        let info = subscriptionPack.entitlementBaseInfo
        let usage = subscriptionPack.usage
        let quota = info?.quota

        let usedDollars = usage?.basicUsageAmount ?? 0
        let limitDollars = quota?.basicUsageLimit ?? 0

        // Reset time: prefer next_billing_time, fall back to end_time
        let resetTimestamp = subscriptionPack.nextBillingTime ?? info?.endTime
        let resetsAt = resetTimestamp.map { Date(timeIntervalSince1970: $0) }

        return TraeUsageSnapshot(
            usedDollars: usedDollars,
            limitDollars: limitDollars,
            resetsAt: resetsAt,
            username: username,
            planName: "Pro")
    }
}
