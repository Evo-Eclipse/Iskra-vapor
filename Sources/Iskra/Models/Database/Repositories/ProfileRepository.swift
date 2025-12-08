import Fluent
import Foundation

/// Repository for Profile entity operations.
struct ProfileRepository: Sendable {
    let database: any Database

    // MARK: - Read Operations

    /// Finds profile by user ID.
    func find(userId: UUID) async throws -> ProfileDTO? {
        try await Profile.find(userId, on: database)?.toDTO()
    }

    /// Checks if user has an active profile.
    func exists(userId: UUID) async throws -> Bool {
        try await Profile.find(userId, on: database) != nil
    }

    // MARK: - Write Operations

    /// Creates profile from approved moderation.
    func create(from moderation: ModerationDTO) async throws -> ProfileDTO? {
        let profile = Profile(
            userId: moderation.userId,
            displayName: moderation.name,
            description: moderation.description,
            photoFileId: moderation.photoFileId,
            city: moderation.city
        )
        try await profile.save(on: database)
        return profile.toDTO()
    }

    /// Updates profile from approved moderation.
    func update(from moderation: ModerationDTO) async throws -> ProfileDTO? {
        guard let profile = try await Profile.find(moderation.userId, on: database) else {
            return nil
        }

        profile.displayName = moderation.name
        profile.description = moderation.description
        profile.photoFileId = moderation.photoFileId
        profile.city = moderation.city

        try await profile.save(on: database)
        return profile.toDTO()
    }

    /// Creates or updates profile from approved moderation.
    func upsert(from moderation: ModerationDTO) async throws -> ProfileDTO? {
        if try await exists(userId: moderation.userId) {
            try await update(from: moderation)
        } else {
            try await create(from: moderation)
        }
    }

    /// Deletes profile.
    func delete(userId: UUID) async throws -> Bool {
        guard let profile = try await Profile.find(userId, on: database) else {
            return false
        }
        try await profile.delete(on: database)
        return true
    }

    // MARK: - Search Operations

    /// Finds candidate profiles for search matching filters.
    /// Excludes profiles the user has already interacted with.
    func findCandidates(
        for userId: UUID,
        filters: FilterDTO,
        excludedUserIds: Set<UUID>,
        limit: Int = 10
    ) async throws -> [ProfileDTO] {
        // Calculate birth date range from age filters
        let now = Date()
        let maxBirthDate = Calendar.iso8601.date(
            byAdding: .year,
            value: -Int(filters.ageMin),
            to: now
        ) ?? now
        let minBirthDate = Calendar.iso8601.date(
            byAdding: .year,
            value: -Int(filters.ageMax) - 1,
            to: now
        ) ?? now

        var allExcluded = excludedUserIds
        allExcluded.insert(userId)

        return try await Profile.query(on: database)
            .join(User.self, on: \Profile.$id == \User.$id)
            .filter(User.self, \.$status == .active)
            .filter(User.self, \.$gender ~~ filters.targetGenders)
            .filter(User.self, \.$birthDate >= minBirthDate)
            .filter(User.self, \.$birthDate <= maxBirthDate)
            .filter(\.$id !~ Array(allExcluded))
            .limit(limit)
            .all()
            .compactMap { $0.toDTO() }
    }
}
