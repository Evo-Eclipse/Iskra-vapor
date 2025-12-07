/// Handler for callback queries from inline keyboards.
protocol CallbackHandler: Sendable {
    /// Handles a callback query.
    /// - Parameters:
    ///   - query: The callback query from Telegram
    ///   - parsed: Pre-parsed callback data (prefix and payload)
    ///   - context: Request-scoped context
    func handle(
        _ query: Components.Schemas.CallbackQuery,
        parsed: ParsedCallback,
        context: UpdateContext
    ) async
}
