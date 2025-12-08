import Vapor

/// User interaction data transfer object.
struct InteractionDTO: Content, Sendable {
    let id: UUID
    let actorId: UUID
    let targetId: UUID
    let action: InteractionAction
    let message: String?
    let isHidden: Bool
    let createdAt: Date
}

// MARK: - Model Conversion

extension Interaction {
    /// Converts Fluent model to DTO.
    func toDTO() -> InteractionDTO? {
        guard let id = id, let createdAt = createdAt else {
            return nil
        }

        return InteractionDTO(
            id: id,
            actorId: actorId,
            targetId: targetId,
            action: action,
            message: message,
            isHidden: isHidden,
            createdAt: createdAt
        )
    }
}
