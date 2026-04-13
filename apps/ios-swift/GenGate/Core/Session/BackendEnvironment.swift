import Foundation

enum BackendEnvironment {
    private static let fallbackBaseURLString = "http://127.0.0.1:8000"

    static var apiBaseURL: URL? {
        if let override = ProcessInfo.processInfo.environment["GENGATE_API_BASE_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty,
           let parsed = URL(string: override) {
            return parsed
        }

        return URL(string: fallbackBaseURLString)
    }
}
