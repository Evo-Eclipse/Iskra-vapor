import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // Configure database
    try configureDatabase(app)

    // Load Telegram configuration
    let telegramConfig = try TelegramConfiguration.fromEnvironment()
    app.storage[TelegramConfigurationKey.self] = telegramConfig

    app.logger.info("Starting Telegram bot in \(telegramConfig.mode) mode")

    // Build shared services
    let router = buildUpdateRouter()
    let sessions = SessionStorage()
    let client = TelegramClientFactory.makeClient(botToken: telegramConfig.botToken)

    // Configure based on mode
    switch telegramConfig.mode {
    case .webhook:
        app.logger.info("Telegram webhook endpoint is \(telegramConfig.webhookURL ?? "not configured")")
        try configureWebhook(app: app, config: telegramConfig, router: router, client: client, sessions: sessions)
    case .polling:
        configurePolling(app: app, config: telegramConfig, router: router, client: client, sessions: sessions)
    }

    // Prune inactive sessions
    app.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .minutes(60), delay: .minutes(60)) { _ in
        let removed = sessions.pruneInactive(olderThan: .seconds(3600 * 24)) // 24 hours
        if removed > 0 {
            app.logger.info("Pruned \(removed) inactive sessions")
        }
    }

    // Register routes
    try routes(app)
}

// MARK: - Router Configuration

/// Builds the update router with all command and callback handlers.
/// This router is shared between webhook and polling modes.
private func buildUpdateRouter() -> UpdateRouter {
    UpdateRouterBuilder()
        .onCommand("start", handler: StartCommandHandler())
        .onCommand("help", handler: HelpCommandHandler())
        .onCallback(prefix: "action", handler: ActionCallbackHandler())
        .onText(EchoTextHandler())
        .onSticker(EchoStickerHandler())
        .build()
}

// MARK: - Webhook Configuration

private func configureWebhook(
    app: Application,
    config: TelegramConfiguration,
    router: UpdateRouter,
    client: Client,
    sessions: SessionStorage
) throws {
    // Register authentication middleware (validates X-Telegram-Bot-Api-Secret-Token)
    app.middleware.use(BotAuthenticationMiddleware(expectedToken: config.webhookSecretToken))

    // Register webhook controller
    let webhookController = TelegramWebhookController(
        router: router,
        client: client,
        db: app.db,
        sessions: sessions
    )
    try app.register(collection: webhookController)

    // Schedule webhook setup after server starts
    app.lifecycle.use(TelegramWebhookLifecycle(config: config))
}

// MARK: - Polling Configuration

private func configurePolling(
    app: Application,
    config: TelegramConfiguration,
    router: UpdateRouter,
    client: Client,
    sessions: SessionStorage
) {
    let pollingService = TelegramPollingService(
        config: config,
        router: router,
        logger: app.logger,
        client: client,
        db: app.db,
        sessions: sessions,
        timeout: config.pollingTimeout,
        limit: config.pollingLimit
    )

    // Register lifecycle handler to start/stop polling
    app.lifecycle.use(TelegramPollingLifecycle(pollingService: pollingService))
}

// MARK: - Database Configuration

private func configureDatabase(_ app: Application) throws {
    try app.databases.use(
        DatabaseConfigurationFactory.postgres(
            configuration: .init(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
                password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
                database: Environment.get("DATABASE_NAME") ?? "vapor_database",
                tls: .prefer(.init(configuration: .clientDefault))
            )
        ),
        as: .psql
    )

    // Register migrations in dependency order
    app.migrations.add(CreateEnumTypes())
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateProfiles())
    app.migrations.add(CreateFilters())
    app.migrations.add(CreateModerations())
    app.migrations.add(CreateInteractions())
    app.migrations.add(CreateMatches())
}
