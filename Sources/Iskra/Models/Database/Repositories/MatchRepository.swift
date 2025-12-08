import Fluent
import Foundation

/// Repository for Match entity operations.
struct MatchRepository: Sendable {
    let database: any Database

    // MARK: - Read Operations

    /// Finds match by ID.
    func find(id: UUID) async throws -> MatchDTO? {
        try await Match.find(id, on: database)?.toDTO()
    }

    /// Finds match between two users.
    func find(userA: UUID, userB: UUID) async throws -> MatchDTO? {
        // Normalize order to match CHECK constraint
        let (first, second) = userA.uuidString < userB.uuidString
            ? (userA, userB)
            : (userB, userA)

        return try await Match.query(on: database)
            .filter(\.$userAId == first)
            .filter(\.$userBId == second)
            .first()?
            .toDTO()
    }

    /// Checks if two users are matched.
    func exists(userA: UUID, userB: UUID) async throws -> Bool {
        try await find(userA: userA, userB: userB) != nil
    }

    /// Gets all matches for a user.
    func findAll(userId: UUID) async throws -> [MatchDTO] {
        try await Match.query(on: database)
            .group(.or) { group in
                group.filter(\.$userAId == userId)
                group.filter(\.$userBId == userId)
            }
            .sort(\.$createdAt, .descending)
            .all()
            .compactMap { $0.toDTO() }
    }

    /// Counts matches for a user.
    func count(userId: UUID) async throws -> Int {
        try await Match.query(on: database)
            .group(.or) { group in
                group.filter(\.$userAId == userId)
                group.filter(\.$userBId == userId)
            }
            .count()
    }

    // MARK: - Write Operations

    /// Creates a match between two users.
    func create(
        userA: UUID,
        userB: UUID,
        matchType: LookingFor,
    ) async throws -> MatchDTO? {
        // Check if match already exists
        if try await exists(userA: userA, userB: userB) {
            return try await find(userA: userA, userB: userB)
        }

        let match = Match(
            userA: userA,
            userB: userB,
            matchType: matchType,
        )
        try await match.save(on: database)
        return match.toDTO()
    }

    /// Deletes a match.
    func delete(userA: UUID, userB: UUID) async throws -> Bool {
        // Normalize order
        let (first, second) = userA.uuidString < userB.uuidString
            ? (userA, userB)
            : (userB, userA)

        guard let match = try await Match.query(on: database)
            .filter(\.$userAId == first)
            .filter(\.$userBId == second)
            .first()
        else {
            return false
        }

        try await match.delete(on: database)
        return true
    }
}
