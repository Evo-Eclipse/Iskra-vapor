/// Handles the /start command.
///
/// The /start command is typically the first interaction with a bot.
/// It can include a deep-link payload: /start payload
struct StartCommandHandler: CommandHandler {
    func handle(
        _ message: Components.Schemas.Message,
        command: BotCommand,
        context: UpdateContext
    ) async {
        context.logger.info(
            "Start command received",
            metadata: [
                "chat_id": "\(message.chat.id)",
                "user_id": "\(message.from?.id ?? 0)",
                "username": "\(message.from?.username ?? "none")",
                "deep_link": "\(command.arguments ?? "none")"
            ]
        )

        // TODO: Send welcome message via Telegram API client
        // TODO: Handle deep-link payload if present (command.arguments)
    }
}
