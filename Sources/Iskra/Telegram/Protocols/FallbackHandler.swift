/// Fallback handler for unrouted updates.
protocol FallbackHandler: Sendable {
    /// Handles an update that no other handler matched.
    /// - Parameters:
    ///   - update: The unhandled update
    ///   - context: Request-scoped context
    func handle(_ update: Components.Schemas.Update, context: UpdateContext) async
}
