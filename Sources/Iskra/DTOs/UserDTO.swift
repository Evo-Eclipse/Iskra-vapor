import Foundation
import Vapor

/// User data transfer object.
/// Value type for external API consumption.
struct UserDTO: Content, Sendable {
    let id: UUID
    let telegramId: Int64
    let telegramUsername: String?
    let birthDate: Date
    let gender: Gender
    let status: UserStatus
    let isMuted: Bool
    let createdAt: Date

    /// User's age in years.
    var age: Int {
        birthDate.ageInYears
    }

    /// Whether user meets minimum age requirement.
    var isEligible: Bool {
        birthDate.isAtLeastAge(16)
    }
}

// MARK: - Model Conversion

extension User {
    /// Converts Fluent model to DTO.
    /// - Returns: UserDTO if model has required fields, nil otherwise.
    func toDTO() -> UserDTO? {
        guard let id = id, let createdAt = createdAt else {
            return nil
        }

        return UserDTO(
            id: id,
            telegramId: telegramId,
            telegramUsername: telegramUsername,
            birthDate: birthDate,
            gender: gender,
            status: status,
            isMuted: isMuted,
            createdAt: createdAt
        )
    }
}
