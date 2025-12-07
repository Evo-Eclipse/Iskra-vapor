import Vapor

/// Operation mode for the Telegram bot.
enum TelegramBotMode: String, Sendable {
    case webhook
    case polling
}

/// Configuration for Telegram Bot API integration.
struct TelegramConfiguration: Sendable {
    /// Default webhook path appended to base URL if not specified.
    static let defaultWebhookPath = "/webhook/telegram"

    /// The bot token from @BotFather.
    let botToken: String

    /// Operation mode: webhook or polling.
    let mode: TelegramBotMode

    /// Optional secret token for webhook validation.
    /// When set, Telegram will send this in the X-Telegram-Bot-Api-Secret-Token header.
    let webhookSecretToken: String?

    /// The full webhook URL that Telegram will POST updates to.
    /// Automatically appends `/webhook/telegram` if the URL doesn't contain a path.
    let webhookURL: String?

    /// Whether to delete the existing webhook on startup before setting a new one.
    let deleteWebhookOnStart: Bool

    // MARK: - Polling Configuration

    /// Long polling timeout in seconds (0-50). Default: 30.
    let pollingTimeout: Int64

    /// Maximum number of updates to retrieve per request (1-100). Default: 100.
    let pollingLimit: Int64

    /// Creates configuration from environment variables.
    /// - Throws: If required environment variables are missing.
    static func fromEnvironment() throws -> TelegramConfiguration {
        guard let botToken = Environment.get("TELEGRAM_BOT_TOKEN") else {
            throw ConfigurationError.missingEnvironmentVariable("TELEGRAM_BOT_TOKEN")
        }

        let mode = Environment.get("TELEGRAM_BOT_MODE")
            .flatMap(TelegramBotMode.init(rawValue:)) ?? .webhook

        let webhookURL = Environment.get("TELEGRAM_WEBHOOK_URL")
            .map(Self.normalizeWebhookURL)

        let deleteOnStart = Environment.get("TELEGRAM_DELETE_WEBHOOK_ON_START")
            .map { $0.lowercased() == "true" || $0 == "1" } ?? true

        let pollingTimeout = Environment.get("TELEGRAM_POLLING_TIMEOUT")
            .flatMap(Int64.init) ?? 30

        let pollingLimit = Environment.get("TELEGRAM_POLLING_LIMIT")
            .flatMap(Int64.init) ?? 100

        return TelegramConfiguration(
            botToken: botToken,
            mode: mode,
            webhookSecretToken: Environment.get("TELEGRAM_WEBHOOK_SECRET"),
            webhookURL: webhookURL,
            deleteWebhookOnStart: deleteOnStart,
            pollingTimeout: pollingTimeout,
            pollingLimit: pollingLimit
        )
    }

    /// Normalizes the webhook URL by appending the default path if needed.
    private static func normalizeWebhookURL(_ url: String) -> String {
        guard let components = URLComponents(string: url) else { return url }

        // If path is empty or just "/", append default webhook path
        let path = components.path
        if path.isEmpty || path == "/" {
            var normalized = components
            normalized.path = defaultWebhookPath
            return normalized.string ?? url
        }

        return url
    }
}

/// Storage key for accessing Telegram configuration from Application.
struct TelegramConfigurationKey: StorageKey {
    typealias Value = TelegramConfiguration
}

/// Extension to easily access Telegram configuration from Application.
extension Application {
    var telegramConfiguration: TelegramConfiguration? {
        get { storage[TelegramConfigurationKey.self] }
        set { storage[TelegramConfigurationKey.self] = newValue }
    }
}

/// Extension to easily access Telegram configuration from Request.
extension Request {
    var telegramConfiguration: TelegramConfiguration {
        get throws {
            guard let config = application.telegramConfiguration else {
                throw ConfigurationError.notConfigured("Telegram")
            }
            return config
        }
    }
}

/// Configuration-related errors.
enum ConfigurationError: Error, LocalizedError {
    case missingEnvironmentVariable(String)
    case notConfigured(String)

    var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let name):
            "Missing required environment variable: \(name)"
        case .notConfigured(let service):
            "\(service) is not configured"
        }
    }
}
