import Logging

/// High-performance message router with O(1) command dispatch.
///
/// Routing priority:
/// 1. Bot commands (/start, /help, etc.) — O(1) Dictionary lookup
/// 2. Media type handlers — O(1) switch
/// 3. Fallback text handler — O(1)
struct MessageRouter: Sendable {
    private let commandHandlers: [String: any CommandHandler]
    private let textHandler: (any TextMessageHandler)?
    private let photoHandler: (any MediaHandler)?
    private let documentHandler: (any MediaHandler)?
    private let videoHandler: (any MediaHandler)?
    private let audioHandler: (any MediaHandler)?
    private let voiceHandler: (any MediaHandler)?
    private let stickerHandler: (any MediaHandler)?
    private let editedMessageHandler: (any EditedMessageHandler)?
    private let channelPostHandler: (any ChannelPostHandler)?

    init(
        commandHandlers: [String: any CommandHandler] = [:],
        textHandler: (any TextMessageHandler)? = nil,
        photoHandler: (any MediaHandler)? = nil,
        documentHandler: (any MediaHandler)? = nil,
        videoHandler: (any MediaHandler)? = nil,
        audioHandler: (any MediaHandler)? = nil,
        voiceHandler: (any MediaHandler)? = nil,
        stickerHandler: (any MediaHandler)? = nil,
        editedMessageHandler: (any EditedMessageHandler)? = nil,
        channelPostHandler: (any ChannelPostHandler)? = nil
    ) {
        self.commandHandlers = commandHandlers
        self.textHandler = textHandler
        self.photoHandler = photoHandler
        self.documentHandler = documentHandler
        self.videoHandler = videoHandler
        self.audioHandler = audioHandler
        self.voiceHandler = voiceHandler
        self.stickerHandler = stickerHandler
        self.editedMessageHandler = editedMessageHandler
        self.channelPostHandler = channelPostHandler
    }

    /// Routes a message to the appropriate handler.
    func route(_ message: Components.Schemas.Message, context: UpdateContext) async {
        // 1. Check for bot commands first — O(1) lookup
        if let command = extractCommand(from: message) {
            if let handler = commandHandlers[command.name] {
                await handler.handle(message, command: command, context: context)
                return
            }
            // Unknown command — log and continue to text handler
            context.logger.debug("Unknown command: /\(command.name)")
        }

        // 2. Route by content type — O(1) switch-like dispatch
        if message.text != nil {
            await textHandler?.handle(message, context: context)
        } else if message.photo != nil {
            await photoHandler?.handle(message, mediaType: .photo, context: context)
        } else if message.document != nil {
            await documentHandler?.handle(message, mediaType: .document, context: context)
        } else if message.video != nil {
            await videoHandler?.handle(message, mediaType: .video, context: context)
        } else if message.audio != nil {
            await audioHandler?.handle(message, mediaType: .audio, context: context)
        } else if message.voice != nil {
            await voiceHandler?.handle(message, mediaType: .voice, context: context)
        } else if message.sticker != nil {
            await stickerHandler?.handle(message, mediaType: .sticker, context: context)
        }
    }

    func routeEdited(_ message: Components.Schemas.Message, context: UpdateContext) async {
        await editedMessageHandler?.handle(message, context: context)
    }

    func routeChannelPost(_ message: Components.Schemas.Message, context: UpdateContext) async {
        await channelPostHandler?.handle(message, context: context)
    }

    // MARK: - Command Extraction

    /// Extracts bot command from message. O(1) for entity check, O(n) for text parsing where n = command length.
    private func extractCommand(from message: Components.Schemas.Message) -> BotCommand? {
        guard let text = message.text, text.hasPrefix("/") else { return nil }

        // Check entities for bot_command type — most reliable
        if let entities = message.entities {
            for entity in entities where entity._type == "bot_command" && entity.offset == 0 {
                let commandLength = Int(entity.length)
                let endIndex = text.index(text.startIndex, offsetBy: min(commandLength, text.count))
                let rawCommand = String(text[..<endIndex])
                return parseCommand(rawCommand, fullText: text)
            }
        }

        // Fallback: simple prefix parsing (for messages without entities)
        let components = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard let firstWord = components.first, firstWord.hasPrefix("/") else { return nil }
        return parseCommand(String(firstWord), fullText: text)
    }

    private func parseCommand(_ rawCommand: String, fullText: String) -> BotCommand {
        // Remove leading "/"
        var commandName = String(rawCommand.dropFirst())

        // Remove @botname suffix if present
        if let atIndex = commandName.firstIndex(of: "@") {
            commandName = String(commandName[..<atIndex])
        }

        // Extract arguments (everything after the command)
        let arguments: String?
        if let spaceIndex = fullText.firstIndex(of: " ") {
            let afterSpace = fullText.index(after: spaceIndex)
            let argsText = String(fullText[afterSpace...]).trimmingCharacters(in: .whitespaces)
            arguments = argsText.isEmpty ? nil : argsText
        } else {
            arguments = nil
        }

        return BotCommand(
            name: commandName.lowercased(),
            arguments: arguments,
            rawCommand: rawCommand
        )
    }
}
