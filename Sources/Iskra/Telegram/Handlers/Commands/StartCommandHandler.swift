/// Handles the /start command.
///
/// The /start command is typically the first interaction with a bot.
/// It can include a deep-link payload: /start payload
///
/// This handler serves as a reference implementation for other command handlers.
struct StartCommandHandler: CommandHandler {
    /// Welcome message template.
    private static let welcomeMessage = """
        👋 Welcome to Iskra

        A high-performance Telegram bot, written in Swift on Server with Vapor and love! 💜
        """

    func handle(_ message: Components.Schemas.Message, command: BotCommand, context: UpdateContext) async {
        context.logger.info(
            "Start command received",
            metadata: [
                "chat_id": "\(message.chat.id)",
                "user_id": "\(message.from?.id ?? 0)",
                "username": "\(message.from?.username ?? "")",
                "deep_link": "\(command.arguments ?? "")"
            ]
        )

        // Send welcome message
        do {
            _ = try await context.client.sendMessage(body: .json(.init(
                chat_id: .case1(message.chat.id),
                text: Self.welcomeMessage
            )))
        } catch {
            context.logger.error("Failed to send welcome message: \(error)")
        }
    }
}
