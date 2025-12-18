/// Handles the /menu command to show the main navigation menu.
struct MenuCommandHandler: CommandHandler {
    func handle(
        _ message: Components.Schemas.Message,
        command: BotCommand,
        context: UpdateContext
    ) async {
        let chatId = message.chat.id
        await MainMenuFlow.show(chatId: chatId, context: context)
    }
}
