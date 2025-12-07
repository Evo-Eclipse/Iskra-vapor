import Foundation
import OpenAPIAsyncHTTPClient

/// Factory for creating Telegram Bot API clients.
///
/// Centralizes client construction to avoid duplication (DRY).
/// Uses value semantics — no synchronization overhead.
enum TelegramClientFactory {
    /// Base URL for Telegram Bot API.
    private static let apiBaseURL = "https://api.telegram.org/bot"

    /// Creates a new Telegram API client for the given bot token.
    /// - Parameter botToken: The bot token from @BotFather
    /// - Returns: A configured API client
    static func makeClient(botToken: String) -> Client {
        guard let serverURL = URL(string: "\(apiBaseURL)\(botToken)") else {
            fatalError("Invalid bot token: unable to construct API URL")
        }
        return Client(
            serverURL: serverURL,
            transport: AsyncHTTPClientTransport()
        )
    }
}
