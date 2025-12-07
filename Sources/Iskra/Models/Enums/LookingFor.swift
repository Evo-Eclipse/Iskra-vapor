/// Relationship goal type.
/// Maps to PostgreSQL `looking_for_type` enum.
enum LookingFor: String, Codable, Sendable, CaseIterable {
    case friendship
    case relationship
}
