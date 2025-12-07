/// Handles the /help command.
struct HelpCommandHandler: CommandHandler {
    func handle(
        _ message: Components.Schemas.Message,
        command: BotCommand,
        context: UpdateContext
    ) async {
        context.logger.info(
            "Help command received",
            metadata: ["chat_id": "\(message.chat.id)"]
        )

        // TODO: Send help message with available commands
    }
}
