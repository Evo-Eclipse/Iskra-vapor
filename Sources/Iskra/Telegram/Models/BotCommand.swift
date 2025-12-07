/// Parsed bot command extracted from a message.
///
/// Commands are regular messages with text starting with `/` and
/// a `bot_command` entity type in the message's entities array.
struct BotCommand: Sendable, Equatable {
    /// Lowercase command name without the leading `/`.
    /// Example: "start" for "/start@MyBot arg1 arg2"
    let name: String

    /// Everything after the command, or nil if no arguments.
    /// Example: "arg1 arg2" for "/start arg1 arg2"
    let arguments: String?

    /// The raw command text including `/` and optional @botname.
    /// Example: "/start@MyBot" for "/start@MyBot arg1 arg2"
    let rawCommand: String
}
