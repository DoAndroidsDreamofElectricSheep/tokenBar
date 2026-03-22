import Foundation

public enum ProviderTokenSource: String, Sendable {
    case environment
    case authFile
}

public struct ProviderTokenResolution: Sendable {
    public let token: String
    public let source: ProviderTokenSource

    public init(token: String, source: ProviderTokenSource) {
        self.token = token
        self.source = source
    }
}

public enum ProviderTokenResolver {
    private static func cleaned(_ raw: String?) -> String? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
            (value.hasPrefix("'") && value.hasSuffix("'"))
        {
            value.removeFirst()
            value.removeLast()
        }

        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func resolveEnv(_ token: String?) -> ProviderTokenResolution? {
        guard let token else { return nil }
        return ProviderTokenResolution(token: token, source: .environment)
    }
}
