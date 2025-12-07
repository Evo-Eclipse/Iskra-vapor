/// Handler for plain text messages (non-command).
protocol TextMessageHandler: Sendable {
    /// Handles a text message that is not a command.
    /// - Parameters:
    ///   - message: The message containing text
    ///   - context: Request-scoped context
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async
}
