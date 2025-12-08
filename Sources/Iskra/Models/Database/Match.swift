import Fluent
import Foundation

/// Mutual match between two users.
/// Created when both users like each other.
final class Match: Model, @unchecked Sendable {
    static let schema = "matches"

    @ID(key: .id)
    var id: UUID?

    /// User with lexicographically smaller ID
    @Field(key: .userAId)
    var userAId: UUID

    /// User with lexicographically larger ID
    @Field(key: .userBId)
    var userBId: UUID

    @Enum(key: .matchType)
    var matchType: LookingFor

    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?

    // MARK: - Initialization

    init() {}

    /// Creates a match ensuring userAId < userBId invariant.
    init(
        id: UUID? = nil,
        userA: UUID,
        userB: UUID,
        matchType: LookingFor,
    ) {
        self.id = id
        // Enforce CHECK constraint: user_a_id < user_b_id
        if userA.uuidString < userB.uuidString {
            userAId = userA
            userBId = userB
        } else {
            userAId = userB
            userBId = userA
        }
        self.matchType = matchType
    }

    /// Checks if the given user ID is part of this match.
    func involves(userId: UUID) -> Bool {
        userAId == userId || userBId == userId
    }

    /// Returns the other user's ID in this match.
    func otherUser(from userId: UUID) -> UUID? {
        if userAId == userId { return userBId }
        if userBId == userId { return userAId }
        return nil
    }
}
