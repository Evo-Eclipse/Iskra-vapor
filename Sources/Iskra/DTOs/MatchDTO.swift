import Vapor

/// Match data transfer object.
struct MatchDTO: Content, Sendable {
    let id: UUID
    let userAId: UUID
    let userBId: UUID
    let matchType: LookingFor
    let createdAt: Date

    /// Checks if the given user ID is part of this match.
    func involves(userId: UUID) -> Bool {
        userAId == userId || userBId == userId
    }

    /// Returns the other user's ID in this match.
    func otherUser(from userId: UUID) -> UUID? {
        if userAId == userId { return userBId }
        if userBId == userId { return userAId }
        return nil
    }
}

// MARK: - Model Conversion

extension Match {
    /// Converts Fluent model to DTO.
    func toDTO() -> MatchDTO? {
        guard let id = id, let createdAt = createdAt else {
            return nil
        }

        return MatchDTO(
            id: id,
            userAId: userAId,
            userBId: userBId,
            matchType: matchType,
            createdAt: createdAt
        )
    }
}
