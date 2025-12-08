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
