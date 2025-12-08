import Fluent
import Foundation

/// Repository for Interaction entity operations.
struct InteractionRepository: Sendable {
    let database: any Database

    // MARK: - Read Operations

    /// Finds interaction by ID.
    func find(id: UUID) async throws -> InteractionDTO? {
        try await Interaction.find(id, on: database)?.toDTO()
    }

    /// Finds interaction between two users.
    func find(actorId: UUID, targetId: UUID) async throws -> InteractionDTO? {
        try await Interaction.query(on: database)
            .filter(\.$actorId == actorId)
            .filter(\.$targetId == targetId)
            .first()?
            .toDTO()
    }

    /// Checks if actor has liked target.
    func hasLiked(actorId: UUID, targetId: UUID) async throws -> Bool {
        try await Interaction.query(on: database)
            .filter(\.$actorId == actorId)
            .filter(\.$targetId == targetId)
            .filter(\.$action == .like)
            .filter(\.$isHidden == false)
            .count() > 0
    }

    /// Gets all user IDs that actor has interacted with (for search exclusion).
    func getInteractedUserIds(actorId: UUID) async throws -> Set<UUID> {
        let interactions = try await Interaction.query(on: database)
            .filter(\.$actorId == actorId)
            .all()

        return Set(interactions.map(\.targetId))
    }

    /// Gets incoming interactions for target (notifications).
    func findIncoming(
        targetId: UUID,
        actions: [InteractionAction] = [.like, .envelope],
        includeHidden: Bool = false,
    ) async throws -> [InteractionDTO] {
        var query = Interaction.query(on: database)
            .filter(\.$targetId == targetId)
            .filter(\.$action ~~ actions)

        if !includeHidden {
            query = query.filter(\.$isHidden == false)
        }

        return try await query
            .sort(\.$createdAt, .descending)
            .all()
            .compactMap { $0.toDTO() }
    }

    // MARK: - Write Operations

    /// Records an interaction.
    func record(
        actorId: UUID,
        targetId: UUID,
        action: InteractionAction,
        message: String? = nil,
    ) async throws -> InteractionDTO? {
        // Check for existing interaction
        if let existing = try await Interaction.query(on: database)
            .filter(\.$actorId == actorId)
            .filter(\.$targetId == targetId)
            .first()
        {
            // Update existing
            existing.action = action
            existing.message = message
            existing.isHidden = false
            try await existing.save(on: database)
            return existing.toDTO()
        }

        // Create new
        let interaction = Interaction(
            actorId: actorId,
            targetId: targetId,
            action: action,
            message: message,
        )
        try await interaction.save(on: database)
        return interaction.toDTO()
    }

    /// Hides an interaction (soft delete).
    func hide(id: UUID) async throws -> Bool {
        guard let interaction = try await Interaction.find(id, on: database) else {
            return false
        }
        interaction.isHidden = true
        try await interaction.save(on: database)
        return true
    }

    /// Hides all interactions from actor to target.
    func hide(actorId: UUID, targetId: UUID) async throws {
        try await Interaction.query(on: database)
            .filter(\.$actorId == actorId)
            .filter(\.$targetId == targetId)
            .set(\.$isHidden, to: true)
            .update()
    }
}
