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
}
