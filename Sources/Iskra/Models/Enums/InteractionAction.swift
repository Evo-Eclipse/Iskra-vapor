/// User interaction action type.
/// Maps to PostgreSQL `interaction_action_type` enum.
enum InteractionAction: String, Codable, Sendable, CaseIterable {
    case pass
    case like
    case envelope
    case report
}
