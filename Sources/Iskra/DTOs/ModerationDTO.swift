import Foundation
import Vapor

/// Moderation request data transfer object.
struct ModerationDTO: Content, Sendable {
    let id: UUID
    let userId: UUID
    let status: ModerationStatus
    let name: String
    let description: String
    let photoFileId: String
    let city: String
    let adminComment: String?
    let createdAt: Date
    let closedAt: Date?
}

// MARK: - Model Conversion

extension Moderation {
    /// Converts Fluent model to DTO.
    func toDTO() -> ModerationDTO? {
        guard let id = id, let createdAt = createdAt else {
            return nil
        }

        return ModerationDTO(
            id: id,
            userId: $user.id,
            status: status,
            name: name,
            description: description,
            photoFileId: photoFileId,
            city: city,
            adminComment: adminComment,
            createdAt: createdAt,
            closedAt: closedAt
        )
    }
}
