import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // Load Telegram configuration
    let telegramConfig = try TelegramConfiguration.fromEnvironment()
    app.storage[TelegramConfigurationKey.self] = telegramConfig

    app.logger.info("Telegram bot mode: \(telegramConfig.mode)")
    app.logger.info("Webhook URL: \(telegramConfig.webhookURL ?? "not configured")")

    // Configure webhook
    guard telegramConfig.mode == .webhook else {
        app.logger.info("Polling mode not yet implemented")
        try routes(app)
        return
    }

    try configureWebhook(app: app, config: telegramConfig)

    // Register routes
    try routes(app)
}

private func configureWebhook(app: Application, config: TelegramConfiguration) throws {
    // Register authentication middleware (validates X-Telegram-Bot-Api-Secret-Token)
    app.middleware.use(BotAuthenticationMiddleware(expectedToken: config.webhookSecretToken))

    // Build update router with O(1) command and callback dispatch
    let router = UpdateRouterBuilder()
        .onCommand("start", handler: StartCommandHandler())
        .onCommand("help", handler: HelpCommandHandler())
        .onCallback(prefix: "action", handler: ActionCallbackHandler())
        .onText(EchoTextHandler())
        .build()

    // Register webhook controller
    let webhookController = TelegramWebhookController(
        router: router,
        botToken: config.botToken
    )
    try app.register(collection: webhookController)

    // Schedule webhook setup after server starts
    app.lifecycle.use(TelegramWebhookLifecycle(config: config))
}
