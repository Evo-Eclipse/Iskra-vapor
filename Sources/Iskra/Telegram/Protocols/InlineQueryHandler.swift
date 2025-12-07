/// Handler for inline queries.
protocol InlineQueryHandler: Sendable {
    /// Handles an inline query.
    /// - Parameters:
    ///   - query: The inline query from Telegram
    ///   - context: Request-scoped context
    func handle(_ query: Components.Schemas.InlineQuery, context: UpdateContext) async
}
