import Logging

/// High-performance update router with O(1) type-based dispatch.
///
/// Architecture:
/// - Type dispatch: O(1) via switch on update type
/// - Command routing: O(1) via Dictionary lookup
/// - Callback routing: O(1) via Dictionary lookup on callback data prefix
/// - Fallback handlers: O(1) for unmatched updates
///
/// Thread Safety:
/// - Immutable after construction
/// - All handlers must be `Sendable`
/// - Parallelism occurs at the Vapor request level, not within routing
struct UpdateRouter: Sendable {
    private let messageRouter: MessageRouter
    private let callbackRouter: CallbackQueryRouter
    private let inlineQueryHandler: (any InlineQueryHandler)?
    private let fallbackHandler: (any FallbackHandler)?

    init(
        messageRouter: MessageRouter = MessageRouter(),
        callbackRouter: CallbackQueryRouter = CallbackQueryRouter(),
        inlineQueryHandler: (any InlineQueryHandler)? = nil,
        fallbackHandler: (any FallbackHandler)? = nil
    ) {
        self.messageRouter = messageRouter
        self.callbackRouter = callbackRouter
        self.inlineQueryHandler = inlineQueryHandler
        self.fallbackHandler = fallbackHandler
    }

    /// Routes an update to the appropriate handler. O(1) dispatch.
    func route(_ update: Components.Schemas.Update, context: UpdateContext) async {
        // O(1) type-based dispatch via switch
        if let message = update.message {
            await messageRouter.route(message, context: context)
        } else if let callbackQuery = update.callback_query {
            await callbackRouter.route(callbackQuery, context: context)
        } else if let inlineQuery = update.inline_query {
            await inlineQueryHandler?.handle(inlineQuery, context: context)
        } else if let editedMessage = update.edited_message {
            await messageRouter.routeEdited(editedMessage, context: context)
        } else if let channelPost = update.channel_post {
            await messageRouter.routeChannelPost(channelPost, context: context)
        } else {
            // Unhandled update types go to fallback
            await fallbackHandler?.handle(update, context: context)
        }
    }
}
