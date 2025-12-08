import Fluent
import Logging

/// Request-scoped context passed to all handlers.
///
/// Contains services and data specific to the current request.
/// Prefer using context properties over creating new instances.
struct UpdateContext: Sendable {
    /// The update's unique identifier from Telegram.
    let updateId: Int64

    /// Request-scoped logger with update metadata.
    let logger: Logger

    /// Telegram Bot API client for sending messages.
    let client: Client

    /// Database connection for persistence operations.
    let db: any Database

    /// Shared session storage for state management.
    let sessions: SessionStorage
}

// MARK: - Session Convenience Methods

extension UpdateContext {
    /// Gets or creates session for the given user.
    func session(for userId: Int64) -> UserSession {
        sessions.getOrCreate(userId: userId)
    }

    /// Updates session for the given user.
    func updateSession(for userId: Int64, _ transform: (inout UserSession) -> Void) {
        sessions.update(userId: userId, transform)
    }

    /// Sets state for the given user.
    func setState(_ state: BotState, for userId: Int64) {
        sessions.setState(state, for: userId)
    }

    /// Gets current state for the given user.
    func state(for userId: Int64) -> BotState {
        sessions.state(for: userId)
    }
}
