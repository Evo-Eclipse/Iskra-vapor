import Fluent
import Foundation

/// Public profile showcase.
/// Data appears here only after moderator approval.
/// 1-to-1 relationship with User.
final class Profile: Model, @unchecked Sendable {
    static let schema = "profiles"

    /// Uses user_id as primary key (1-to-1 relationship)
    @ID(custom: .userId, generatedBy: .user)
    var id: UUID?

    @Parent(key: .userId)
    var user: User

    @Field(key: .displayName)
    var displayName: String

    @Field(key: .description)
    var description: String

    @Field(key: .photoFileId)
    var photoFileId: String

    @Field(key: .city)
    var city: String

    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?

    // MARK: - Initialization

    init() {}

    init(
        userId: UUID,
        displayName: String,
        description: String,
        photoFileId: String,
        city: String,
    ) {
        id = userId
        $user.id = userId
        self.displayName = displayName
        self.description = description
        self.photoFileId = photoFileId
        self.city = city
    }
}
