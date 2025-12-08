/// Gender identity type for user profiles.
/// Maps to PostgreSQL `gender_type` enum.
enum Gender: String, Codable, Sendable, CaseIterable {
    case male
    case female
}
