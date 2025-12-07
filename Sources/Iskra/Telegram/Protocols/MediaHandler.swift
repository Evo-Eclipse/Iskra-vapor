/// Handler for media messages (photos, documents, etc.)
protocol MediaHandler: Sendable {
    /// Handles a media message.
    /// - Parameters:
    ///   - message: The message containing media
    ///   - mediaType: The type of media in the message
    ///   - context: Request-scoped context
    func handle(
        _ message: Components.Schemas.Message,
        mediaType: MediaType,
        context: UpdateContext
    ) async
}

/// Media types for routing.
enum MediaType: String, Sendable {
    case photo
    case document
    case video
    case audio
    case voice
    case sticker
}
