import Foundation

enum BackendEnvironment {
    enum BackendBaseURLError: LocalizedError {
        case invalidBaseURL

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Backend base URL phải là URL http/https hợp lệ."
            }
        }
    }

    private static let fallbackBaseURLString = "http://127.0.0.1:8000"
    private static let persistedBaseURLOverrideKey = "gengate.backend.base_url_override"

    static var persistedBaseURLOverride: String? {
        sanitized(UserDefaults.standard.string(forKey: persistedBaseURLOverrideKey))
    }

    static var environmentBaseURLOverride: String? {
        sanitized(ProcessInfo.processInfo.environment["GENGATE_API_BASE_URL"])
    }

    static var apiBaseURL: URL? {
        if let persisted = parseBaseURL(from: persistedBaseURLOverride) {
            return persisted
        }

        if let environment = parseBaseURL(from: environmentBaseURLOverride) {
            return environment
        }

        return URL(string: fallbackBaseURLString)
    }

    static func savePersistedBaseURLOverride(_ rawValue: String?) throws {
        guard let normalized = sanitized(rawValue) else {
            UserDefaults.standard.removeObject(forKey: persistedBaseURLOverrideKey)
            return
        }

        guard let parsed = parseBaseURL(from: normalized) else {
            throw BackendBaseURLError.invalidBaseURL
        }

        UserDefaults.standard.set(parsed.absoluteString, forKey: persistedBaseURLOverrideKey)
    }

    private static func sanitized(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func parseBaseURL(from value: String?) -> URL? {
        guard let value = sanitized(value),
              let parsed = URL(string: value),
              let scheme = parsed.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              parsed.host != nil else {
            return nil
        }

        return parsed
    }
}
