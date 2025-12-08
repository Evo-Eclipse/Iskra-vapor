import Fluent
import Foundation

/// Repository for Moderation entity operations.
struct ModerationRepository: Sendable {
    let database: any Database

    // MARK: - Read Operations

    /// Finds moderation by ID.
    func find(id: UUID) async throws -> ModerationDTO? {
        try await Moderation.find(id, on: database)?.toDTO()
    }

    /// Finds pending moderation for user.
    func findPending(userId: UUID) async throws -> ModerationDTO? {
        try await Moderation.query(on: database)
            .filter(\.$user.$id == userId)
            .filter(\.$status == .pending)
            .first()?
            .toDTO()
    }

    /// Gets all pending moderations for admin queue.
    func findAllPending(limit: Int = 50) async throws -> [ModerationDTO] {
        try await Moderation.query(on: database)
            .filter(\.$status == .pending)
            .sort(\.$createdAt, .ascending)
            .limit(limit)
            .all()
            .compactMap { $0.toDTO() }
    }

    /// Counts pending moderations.
    func countPending() async throws -> Int {
        try await Moderation.query(on: database)
            .filter(\.$status == .pending)
            .count()
    }

    // MARK: - Write Operations

    /// Creates pending moderation request.
    func createPending(
        userId: UUID,
        name: String,
        description: String,
        photoFileId: String,
        city: String,
    ) async throws -> ModerationDTO? {
        let moderation = Moderation(
            userId: userId,
            status: .pending,
            name: name,
            description: description,
            photoFileId: photoFileId,
            city: city,
        )
        try await moderation.save(on: database)
        return moderation.toDTO()
    }

    /// Approves moderation.
    func approve(id: UUID, comment: String? = nil) async throws -> ModerationDTO? {
        guard let moderation = try await Moderation.find(id, on: database) else {
            return nil
        }

        moderation.status = .approved
        moderation.adminComment = comment
        moderation.closedAt = Date()

        try await moderation.save(on: database)
        return moderation.toDTO()
    }

    /// Rejects moderation.
    func reject(id: UUID, reason: String, comment: String? = nil) async throws -> ModerationDTO? {
        guard let moderation = try await Moderation.find(id, on: database) else {
            return nil
        }

        moderation.status = .rejected
        moderation.adminComment = comment ?? reason
        moderation.closedAt = Date()

        try await moderation.save(on: database)
        return moderation.toDTO()
    }

    /// Cancels pending moderation (user withdrew submission).
    func cancel(id: UUID) async throws -> Bool {
        guard let moderation = try await Moderation.find(id, on: database),
              moderation.status == .pending
        else {
            return false
        }

        try await moderation.delete(on: database)
        return true
    }
}
