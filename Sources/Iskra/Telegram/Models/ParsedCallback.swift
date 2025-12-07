/// Parsed callback query data.
///
/// Callback data convention: "prefix:payload" or "prefix:subaction:payload"
/// The router extracts the prefix (before first ":") for O(1) lookup.
struct ParsedCallback: Sendable, Equatable {
    /// The callback query ID from Telegram.
    let id: String

    /// The raw callback data string.
    let data: String

    /// The prefix extracted from data (before first ":").
    /// Example: "menu" for "menu:settings:audio"
    let prefix: String

    /// Everything after the prefix, or nil if no payload.
    /// Example: "settings:audio" for "menu:settings:audio"
    let payload: String?

    /// Parses callback data into prefix and payload. O(n) where n = prefix length.
    static func parse(id: String, data: String) -> ParsedCallback {
        guard let colonIndex = data.firstIndex(of: ":") else {
            return ParsedCallback(id: id, data: data, prefix: data, payload: nil)
        }

        let prefix = String(data[..<colonIndex])
        let payloadStart = data.index(after: colonIndex)
        let payload = payloadStart < data.endIndex ? String(data[payloadStart...]) : nil

        return ParsedCallback(id: id, data: data, prefix: prefix, payload: payload)
    }
}
