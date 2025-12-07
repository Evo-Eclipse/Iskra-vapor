/// Fluent builder for constructing UpdateRouter.
///
/// Example:
/// ```swift
/// let router = UpdateRouterBuilder()
///     .onCommand("start", handler: StartCommandHandler())
///     .onCommand("help", handler: HelpCommandHandler())
///     .onCallback(prefix: "menu", handler: MenuCallbackHandler())
///     .onText(EchoHandler())
///     .build()
/// ```
struct UpdateRouterBuilder: Sendable {
    private var commandHandlers: [String: any CommandHandler] = [:]
    private var callbackPrefixHandlers: [String: any CallbackHandler] = [:]
    private var textHandler: (any TextMessageHandler)?
    private var photoHandler: (any MediaHandler)?
    private var documentHandler: (any MediaHandler)?
    private var videoHandler: (any MediaHandler)?
    private var audioHandler: (any MediaHandler)?
    private var voiceHandler: (any MediaHandler)?
    private var stickerHandler: (any MediaHandler)?
    private var editedMessageHandler: (any EditedMessageHandler)?
    private var channelPostHandler: (any ChannelPostHandler)?
    private var inlineQueryHandler: (any InlineQueryHandler)?
    private var callbackFallback: (any CallbackHandler)?
    private var fallbackHandler: (any FallbackHandler)?

    init() {}

    // MARK: - Command Handlers

    /// Registers a command handler. O(1) registration, O(1) lookup at runtime.
    func onCommand(_ command: String, handler: any CommandHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.commandHandlers[command.lowercased()] = handler
        return copy
    }

    // MARK: - Callback Handlers

    /// Registers a callback handler by data prefix. O(1) registration, O(1) lookup.
    func onCallback(prefix: String, handler: any CallbackHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.callbackPrefixHandlers[prefix] = handler
        return copy
    }

    /// Registers a fallback handler for callback queries with unknown prefixes.
    func onUnknownCallback(_ handler: any CallbackHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.callbackFallback = handler
        return copy
    }

    // MARK: - Message Handlers

    /// Registers a text message handler (non-command text).
    func onText(_ handler: any TextMessageHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.textHandler = handler
        return copy
    }

    /// Registers a photo handler.
    func onPhoto(_ handler: any MediaHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.photoHandler = handler
        return copy
    }

    /// Registers a document handler.
    func onDocument(_ handler: any MediaHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.documentHandler = handler
        return copy
    }

    /// Registers a video handler.
    func onVideo(_ handler: any MediaHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.videoHandler = handler
        return copy
    }

    /// Registers an audio handler.
    func onAudio(_ handler: any MediaHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.audioHandler = handler
        return copy
    }

    /// Registers a voice message handler.
    func onVoice(_ handler: any MediaHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.voiceHandler = handler
        return copy
    }

    /// Registers a sticker handler.
    func onSticker(_ handler: any MediaHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.stickerHandler = handler
        return copy
    }

    // MARK: - Other Update Types

    /// Registers an edited message handler.
    func onEditedMessage(_ handler: any EditedMessageHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.editedMessageHandler = handler
        return copy
    }

    /// Registers a channel post handler.
    func onChannelPost(_ handler: any ChannelPostHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.channelPostHandler = handler
        return copy
    }

    /// Registers an inline query handler.
    func onInlineQuery(_ handler: any InlineQueryHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.inlineQueryHandler = handler
        return copy
    }

    /// Registers a fallback handler for unrouted updates.
    func onFallback(_ handler: any FallbackHandler) -> UpdateRouterBuilder {
        var copy = self
        copy.fallbackHandler = handler
        return copy
    }

    // MARK: - Build

    /// Builds the immutable UpdateRouter.
    func build() -> UpdateRouter {
        let messageRouter = MessageRouter(
            commandHandlers: commandHandlers,
            textHandler: textHandler,
            photoHandler: photoHandler,
            documentHandler: documentHandler,
            videoHandler: videoHandler,
            audioHandler: audioHandler,
            voiceHandler: voiceHandler,
            stickerHandler: stickerHandler,
            editedMessageHandler: editedMessageHandler,
            channelPostHandler: channelPostHandler
        )

        let callbackRouter = CallbackQueryRouter(
            prefixHandlers: callbackPrefixHandlers,
            fallbackHandler: callbackFallback
        )

        return UpdateRouter(
            messageRouter: messageRouter,
            callbackRouter: callbackRouter,
            inlineQueryHandler: inlineQueryHandler,
            fallbackHandler: fallbackHandler
        )
    }
}
