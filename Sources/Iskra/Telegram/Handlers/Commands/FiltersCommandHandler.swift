import Foundation

/// Handles /filters command to open search filter settings.
struct FiltersCommandHandler: CommandHandler {

    func handle(_ message: Components.Schemas.Message, command: BotCommand, context: UpdateContext) async {
        let chatId = message.chat.id

        // Check if user is registered
        do {
            guard let _ = try await context.users.find(telegramId: chatId) else {
                // User not registered, prompt to start
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: "Please use /start to register first."
                )))
                return
            }

            await SearchSettingsFlow.showMenu(chatId: chatId, context: context)
        } catch {
            context.logger.error("Failed to handle /filters: \(error)")
        }
    }
}
