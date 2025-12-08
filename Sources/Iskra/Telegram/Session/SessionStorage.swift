import NIOConcurrencyHelpers

/// Thread-safe session storage for Telegram bot users.
///
/// Uses `NIOLockedValueBox` for O(1) synchronized access without actor overhead.
/// Sessions are keyed by Telegram user ID (Int64).
///
/// Performance characteristics:
/// - O(1) lookup, insert, update via Dictionary
/// - Single lock for all operations (sufficient for typical bot loads)
/// - No context switching — pure lock-based synchronization
///
/// Thread Safety:
/// - All public methods are thread-safe
/// - Mutations occur within locked scope
/// - Value semantics prevent data races on returned sessions
final class SessionStorage: Sendable {
    /// Internal storage: userId → session mapping.
    private let sessions: NIOLockedValueBox<[Int64: UserSession]>

    /// Creates an empty session storage.
    init() {
        self.sessions = NIOLockedValueBox([:])
    }

    // MARK: - Read Operations

    /// Retrieves session for user, creating new one if not exists.
    /// - Parameter userId: Telegram user ID
    /// - Returns: Existing or newly created session
    func getOrCreate(userId: Int64) -> UserSession {
        sessions.withLockedValue { dict in
            if let existing = dict[userId] {
                return existing
            }
            let newSession = UserSession()
            dict[userId] = newSession
            return newSession
        }
    }

    /// Retrieves session for user if it exists.
    /// - Parameter userId: Telegram user ID
    /// - Returns: Session or nil if not found
    func get(userId: Int64) -> UserSession? {
        sessions.withLockedValue { $0[userId] }
    }

    /// Returns current state for user.
    /// - Parameter userId: Telegram user ID
    /// - Returns: Current bot state, or `.idle` if no session
    func state(for userId: Int64) -> BotState {
        sessions.withLockedValue { $0[userId]?.state ?? .idle }
    }

    // MARK: - Write Operations

    /// Updates session for user, creating if not exists.
    /// Activity timestamp is automatically updated.
    ///
    /// - Warning: The transform closure executes while holding the lock.
    ///   Long-running operations will block all other session access.
    ///   Keep transforms fast and synchronous.
    ///
    /// - Parameters:
    ///   - userId: Telegram user ID
    ///   - transform: Mutation closure applied to session
    func update(userId: Int64, _ transform: (inout UserSession) -> Void) {
        sessions.withLockedValue { dict in
            var session = dict[userId] ?? UserSession()
            transform(&session)
            session.lastActivityAt = .now
            dict[userId] = session
        }
    }

    /// Updates session and returns a result.
    /// Activity timestamp is automatically updated.
    ///
    /// - Warning: The transform closure executes while holding the lock.
    ///   Long-running operations will block all other session access.
    ///   Keep transforms fast and synchronous.
    ///
    /// - Parameters:
    ///   - userId: Telegram user ID
    ///   - transform: Mutation closure returning a value (keep it fast)
    /// - Returns: Result from transform closure
    func updateReturning<T>(userId: Int64, _ transform: (inout UserSession) -> T) -> T {
        sessions.withLockedValue { dict in
            var session = dict[userId] ?? UserSession()
            let result = transform(&session)
            session.lastActivityAt = .now
            dict[userId] = session
            return result
        }
    }

    /// Sets state for user, creating session if not exists.
    /// - Parameters:
    ///   - state: New bot state
    ///   - userId: Telegram user ID
    func setState(_ state: BotState, for userId: Int64) {
        update(userId: userId) { $0.state = state }
    }

    /// Resets session to idle state, clearing temporary data.
    /// - Parameter userId: Telegram user ID
    func reset(userId: Int64) {
        update(userId: userId) { $0.reset() }
    }

    /// Removes session entirely.
    /// - Parameter userId: Telegram user ID
    func remove(userId: Int64) {
        sessions.withLockedValue { _ = $0.removeValue(forKey: userId) }
    }

    // MARK: - Maintenance

    /// Removes sessions inactive for longer than specified duration.
    /// - Parameter duration: Maximum inactivity duration
    /// - Returns: Number of sessions removed
    @discardableResult
    func pruneInactive(olderThan duration: Duration) -> Int {
        let cutoff = ContinuousClock.now - duration
        return sessions.withLockedValue { dict in
            let before = dict.count
            dict = dict.filter { $0.value.lastActivityAt >= cutoff }
            return before - dict.count
        }
    }

    /// Returns total number of active sessions.
    var count: Int {
        sessions.withLockedValue { $0.count }
    }
}
