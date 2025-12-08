/// Profile moderation request status.
/// Maps to PostgreSQL `moderation_status_type` enum.
enum ModerationStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case approved
    case rejected
}
