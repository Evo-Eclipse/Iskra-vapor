/// Handler for edited messages.
protocol EditedMessageHandler: Sendable {
    /// Handles an edited message.
    /// - Parameters:
    ///   - message: The edited message
    ///   - context: Request-scoped context
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async
}
