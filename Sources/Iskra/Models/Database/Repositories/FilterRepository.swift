import Fluent
import Foundation

/// Repository for Filter entity operations.
struct FilterRepository: Sendable {
    let database: any Database

    // MARK: - Read Operations

    /// Finds filter settings for user.
    func find(userId: UUID) async throws -> FilterDTO? {
        try await Filter.find(userId, on: database)?.toDTO()
    }

    /// Checks if user has filter settings.
    func exists(userId: UUID) async throws -> Bool {
        try await Filter.find(userId, on: database) != nil
    }

    // MARK: - Write Operations

    /// Creates filter settings.
    func create(
        userId: UUID,
        targetGenders: [Gender],
        ageMin: Int16,
        ageMax: Int16,
        lookingFor: [LookingFor],
    ) async throws -> FilterDTO? {
        let filter = Filter(
            userId: userId,
            targetGenders: targetGenders,
            ageMin: ageMin,
            ageMax: ageMax,
            lookingFor: lookingFor,
        )
        try await filter.save(on: database)
        return filter.toDTO()
    }

    /// Updates filter settings.
    func update(
        userId: UUID,
        targetGenders: [Gender]? = nil,
        ageMin: Int16? = nil,
        ageMax: Int16? = nil,
        lookingFor: [LookingFor]? = nil,
    ) async throws -> FilterDTO? {
        guard let filter = try await Filter.find(userId, on: database) else {
            return nil
        }

        if let targetGenders { filter.targetGenders = targetGenders }
        if let ageMin { filter.ageMin = ageMin }
        if let ageMax { filter.ageMax = ageMax }
        if let lookingFor { filter.lookingFor = lookingFor }

        try await filter.save(on: database)
        return filter.toDTO()
    }

    /// Creates or updates filter settings.
    func upsert(
        userId: UUID,
        targetGenders: [Gender],
        ageMin: Int16,
        ageMax: Int16,
        lookingFor: [LookingFor],
    ) async throws -> FilterDTO? {
        if try await exists(userId: userId) {
            try await update(
                userId: userId,
                targetGenders: targetGenders,
                ageMin: ageMin,
                ageMax: ageMax,
                lookingFor: lookingFor,
            )
        } else {
            try await create(
                userId: userId,
                targetGenders: targetGenders,
                ageMin: ageMin,
                ageMax: ageMax,
                lookingFor: lookingFor,
            )
        }
    }

    /// Deletes filter settings.
    func delete(userId: UUID) async throws -> Bool {
        guard let filter = try await Filter.find(userId, on: database) else {
            return false
        }
        try await filter.delete(on: database)
        return true
    }
}
