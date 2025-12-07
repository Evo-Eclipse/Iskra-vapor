/// Handler for channel posts.
protocol ChannelPostHandler: Sendable {
    /// Handles a channel post.
    /// - Parameters:
    ///   - message: The channel post message
    ///   - context: Request-scoped context
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async
}
