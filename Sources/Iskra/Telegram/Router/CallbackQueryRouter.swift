import Logging

/// High-performance callback query router with O(1) prefix-based dispatch.
///
/// Callback data convention: "prefix:payload" or "prefix:subaction:payload"
/// Router extracts the prefix (before first ":") for O(1) lookup.
struct CallbackQueryRouter: Sendable {
    private let prefixHandlers: [String: any CallbackHandler]
    private let fallbackHandler: (any CallbackHandler)?

    init(
        prefixHandlers: [String: any CallbackHandler] = [:],
        fallbackHandler: (any CallbackHandler)? = nil
    ) {
        self.prefixHandlers = prefixHandlers
        self.fallbackHandler = fallbackHandler
    }

    /// Routes a callback query by data prefix. O(1) lookup.
    func route(_ query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        guard let data = query.data else {
            context.logger.debug("Callback received without data", metadata: ["id": "\(query.id)"])
            return
        }

        let parsed = ParsedCallback.parse(id: query.id, data: data)

        if let handler = prefixHandlers[parsed.prefix] {
            await handler.handle(query, parsed: parsed, context: context)
        } else {
            await fallbackHandler?.handle(query, parsed: parsed, context: context)
                ?? context.logger.debug("No callback handler found", metadata: ["prefix": "\(parsed.prefix)"])
        }
    }
}
