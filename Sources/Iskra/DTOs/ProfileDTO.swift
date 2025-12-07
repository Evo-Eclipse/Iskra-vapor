import Foundation
import Vapor

/// Profile data transfer object.
/// Public showcase data for display.
struct ProfileDTO: Content, Sendable {
    let userId: UUID
    let displayName: String
    let description: String
    let photoFileId: String
    let city: String
    let updatedAt: Date?
}

// MARK: - Model Conversion

extension Profile {
    /// Converts Fluent model to DTO.
    func toDTO() -> ProfileDTO? {
        guard let userId = id else {
            return nil
        }

        return ProfileDTO(
            userId: userId,
            displayName: displayName,
            description: description,
            photoFileId: photoFileId,
            city: city,
            updatedAt: updatedAt
        )
    }
}
