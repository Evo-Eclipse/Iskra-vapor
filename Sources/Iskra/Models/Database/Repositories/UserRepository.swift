import Fluent
import Foundation

/// Repository for User entity operations.
/// Struct-based for stack allocation and Sendable compliance.
struct UserRepository: Sendable {
    let database: any Database

    // MARK: - Read Operations

    /// Finds user by internal UUID.
    func find(id: UUID) async throws -> UserDTO? {
        try await User.find(id, on: database)?.toDTO()
    }

    /// Finds user by Telegram ID.
    func find(telegramId: Int64) async throws -> UserDTO? {
        try await User.query(on: database)
            .filter(\.$telegramId == telegramId)
            .first()?
            .toDTO()
    }

    /// Checks if user exists by Telegram ID.
    func exists(telegramId: Int64) async throws -> Bool {
        try await User.query(on: database)
            .filter(\.$telegramId == telegramId)
            .count() > 0
    }

    // MARK: - Write Operations

    /// Creates a new user during onboarding.
    /// Per UserFlow: gender is requested before birth date.
    func create(
        telegramId: Int64,
        telegramUsername: String?,
        gender: Gender,
        birthDate: Date,
    ) async throws -> UserDTO? {
        let user = User(
            telegramId: telegramId,
            telegramUsername: telegramUsername,
            birthDate: birthDate,
            gender: gender,
            status: birthDate.isAtLeastAge(16) ? .active : .archived,
            isMuted: false,
        )
        try await user.save(on: database)
        return user.toDTO()
    }

    /// Updates user status.
    func updateStatus(_ status: UserStatus, for userId: UUID) async throws {
        try await User.query(on: database)
            .filter(\.$id == userId)
            .set(\.$status, to: status)
            .update()
    }

    /// Updates user's Telegram username.
    func updateUsername(_ username: String?, for userId: UUID) async throws {
        try await User.query(on: database)
            .filter(\.$id == userId)
            .set(\.$telegramUsername, to: username)
            .update()
    }

    /// Sets muted status (spam-block).
    func setMuted(_ isMuted: Bool, for userId: UUID) async throws {
        try await User.query(on: database)
            .filter(\.$id == userId)
            .set(\.$isMuted, to: isMuted)
            .update()
    }

    // MARK: - Query Operations

    /// Finds users eligible for age-based status update (archived users who turned 16).
    func findNewlyEligibleUsers() async throws -> [UserDTO] {
        let sixteenYearsAgo = Calendar.iso8601.date(
            byAdding: .year,
            value: -16,
            to: Date(),
        ) ?? Date()

        return try await User.query(on: database)
            .filter(\.$status == .archived)
            .filter(\.$birthDate <= sixteenYearsAgo)
            .all()
            .compactMap { $0.toDTO() }
    }
}
