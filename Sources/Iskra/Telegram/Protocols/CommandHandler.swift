/// Handler for bot commands (/start, /help, etc.)
///
/// Commands are regular messages with text starting with `/` and
/// a `bot_command` entity in the message's entities array.
protocol CommandHandler: Sendable {
    /// Handles a bot command.
    /// - Parameters:
    ///   - message: The message containing the command
    ///   - command: Parsed command name and arguments
    ///   - context: Request-scoped context (logger, bot token, etc.)
    func handle(
        _ message: Components.Schemas.Message,
        command: BotCommand,
        context: UpdateContext
    ) async
}
