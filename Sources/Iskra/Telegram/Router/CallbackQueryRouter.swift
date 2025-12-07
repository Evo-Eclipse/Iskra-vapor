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
            context.logger.debug("Callback query without data", metadata: ["id": "\(query.id)"])
            return
        }

        let (prefix, payload) = parseCallbackData(data)
        let parsedCallback = ParsedCallback(
            id: query.id,
            data: data,
            prefix: prefix,
            payload: payload
        )

        if let handler = prefixHandlers[prefix] {
            await handler.handle(query, parsed: parsedCallback, context: context)
        } else {
            await fallbackHandler?.handle(query, parsed: parsedCallback, context: context)
                ?? context.logger.debug("No handler for callback prefix", metadata: ["prefix": "\(prefix)"])
        }
    }

    /// Parses callback data into prefix and payload. O(n) where n = prefix length (typically < 20 chars).
    private func parseCallbackData(_ data: String) -> (prefix: String, payload: String?) {
        guard let colonIndex = data.firstIndex(of: ":") else {
            return (data, nil)
        }

        let prefix = String(data[..<colonIndex])
        let payloadStart = data.index(after: colonIndex)
        let payload = payloadStart < data.endIndex ? String(data[payloadStart...]) : nil

        return (prefix, payload)
    }
}
