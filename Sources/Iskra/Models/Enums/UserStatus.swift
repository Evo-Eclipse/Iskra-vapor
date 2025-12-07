/// User account lifecycle status.
/// Maps to PostgreSQL `user_status_type` enum.
enum UserStatus: String, Codable, Sendable, CaseIterable {
    /// Profile is visible in search (all ok)
    case active
    /// Profile not visible (user hid/paused it)
    case paused
    /// Profile not visible (admin ban)
    case banned
    /// Profile not visible (system hold, e.g. age < 16)
    case archived
}
