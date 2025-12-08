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

    /// Admin group chat ID for moderation (optional).
    let adminChatId: Int64?
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

// MARK: - Repository Access

extension UpdateContext {
    /// User repository for account operations.
    var users: UserRepository { UserRepository(database: db) }

    /// Profile repository for showcase operations.
    var profiles: ProfileRepository { ProfileRepository(database: db) }

    /// Filter repository for search settings.
    var filters: FilterRepository { FilterRepository(database: db) }

    /// Interaction repository for likes/passes.
    var interactions: InteractionRepository { InteractionRepository(database: db) }

    /// Match repository for mutual likes.
    var matches: MatchRepository { MatchRepository(database: db) }

    /// Moderation repository for admin queue.
    var moderations: ModerationRepository { ModerationRepository(database: db) }
}
