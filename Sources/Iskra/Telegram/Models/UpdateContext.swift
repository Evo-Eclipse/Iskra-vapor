import Logging

/// Request-scoped context passed to all handlers.
///
/// Contains data specific to the current request that should not be
/// injected at initialization time. Long-lived services should be
/// injected via constructor DI instead.
struct UpdateContext: Sendable {
    /// The update's unique identifier from Telegram.
    let updateId: Int64

    /// Request-scoped logger with update metadata.
    let logger: Logger

    /// Bot token for making API calls.
    let botToken: String
}
