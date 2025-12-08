/// Handles the /search command to show the search menu.
struct SearchCommandHandler: CommandHandler {
    func handle(
        _ message: Components.Schemas.Message,
        command: BotCommand,
        context: UpdateContext
    ) async {
        let chatId = message.chat.id
        await SearchFlow.Presenter.showMenu(chatId: chatId, context: context)
    }
}
