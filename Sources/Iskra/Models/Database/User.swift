import Fluent
import Foundation

/// Core user account entity.
/// Stores technical data and rarely-changed information.
/// Property wrappers interact poorly with `Sendable` checking.
final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .telegramId)
    var telegramId: Int64

    @OptionalField(key: .telegramUsername)
    var telegramUsername: String?

    @Field(key: .birthDate)
    var birthDate: Date

    @Enum(key: .gender)
    var gender: Gender

    @Enum(key: .status)
    var status: UserStatus

    @Field(key: .isMuted)
    var isMuted: Bool

    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?

    // MARK: - Relationships

    // Note: Profile uses user_id as its primary key (1-to-1), so no @Child relationship.
    // Fetch profile via ProfileRepository.find(userId:) instead.

    @OptionalChild(for: \.$user)
    var filter: Filter?

    @Children(for: \.$user)
    var moderations: [Moderation]

    // MARK: - Initialization

    init() {}

    init(
        id: UUID? = nil,
        telegramId: Int64,
        telegramUsername: String? = nil,
        birthDate: Date,
        gender: Gender,
        status: UserStatus = .active,
        isMuted: Bool = false
    ) {
        self.id = id
        self.telegramId = telegramId
        self.telegramUsername = telegramUsername
        self.birthDate = birthDate
        self.gender = gender
        self.status = status
        self.isMuted = isMuted
    }
}

// MARK: - Computed Properties

extension User {
    /// User's age in years calculated from birth date.
    var age: Int {
        birthDate.ageInYears
    }

    /// Whether the user meets minimum age requirement (16+).
    var isEligible: Bool {
        birthDate.isAtLeastAge(16)
    }
}
