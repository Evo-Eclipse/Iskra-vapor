import Foundation

/// Errors related to Telegram Bot API operations.
enum TelegramError: Error, LocalizedError, Sendable {
    /// Failed to decode an update from webhook payload.
    case invalidUpdatePayload(underlyingError: any Error)

    /// Webhook authentication failed.
    case authenticationFailed

    /// Required configuration is missing.
    case configurationMissing(String)

    /// API call failed with an error response.
    case apiError(statusCode: Int, description: String?)

    /// Network or transport error.
    case networkError(underlyingError: any Error)

    var errorDescription: String? {
        switch self {
        case .invalidUpdatePayload(let error):
            "Invalid update payload: \(error.localizedDescription)"
        case .authenticationFailed:
            "Webhook authentication failed"
        case .configurationMissing(let key):
            "Missing configuration: \(key)"
        case .apiError(let statusCode, let description):
            "API error (\(statusCode)): \(description ?? "Unknown error")"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        }
    }
}
