import Vapor

/// Search filter settings data transfer object.
struct FilterDTO: Content, Sendable {
    let userId: UUID
    let targetGenders: [Gender]
    let ageMin: Int16
    let ageMax: Int16
    let lookingFor: [LookingFor]
}

// MARK: - Model Conversion

extension Filter {
    /// Converts Fluent model to DTO.
    func toDTO() -> FilterDTO? {
        guard let userId = id else {
            return nil
        }

        return FilterDTO(
            userId: userId,
            targetGenders: targetGenders,
            ageMin: ageMin,
            ageMax: ageMax,
            lookingFor: lookingFor
        )
    }
}
