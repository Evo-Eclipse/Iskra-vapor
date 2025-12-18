/// Handles the /help command.
/// Shows available commands and quick navigation buttons.
struct HelpCommandHandler: CommandHandler {
    func handle(
        _ message: Components.Schemas.Message,
        command: BotCommand,
        context: UpdateContext
    ) async {
        let chatId = message.chat.id
        
        context.logger.info(
            "Help command received",
            metadata: ["chat_id": "\(chatId)"]
        )
        
        let text = L10n["help.title"] + "\n\n" + L10n["help.commands"] + "\n\n" + L10n["help.hint"]
        
        var kb = KeyboardBuilder(type: .inline)
        kb.button(text: L10n["help.buttons.surf"], callbackData: "search:start")
        kb.button(text: L10n["help.buttons.profile"], callbackData: "profile:edit:menu")
        
        do {
            _ = try await context.client.sendMessage(body: .json(.init(
                chat_id: .case1(chatId),
                text: text,
                reply_markup: .InlineKeyboardMarkup(kb.buildInline())
            )))
        } catch {
            context.logger.error("Failed to send help message: \(error)")
        }
    }
}
