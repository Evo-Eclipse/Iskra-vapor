import Fluent
import Foundation

/// Profile change moderation request.
/// All profile edits pass through this gateway.
final class Moderation: Model, @unchecked Sendable {
    static let schema = "moderations"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: .userId)
    var user: User

    @Enum(key: .status)
    var status: ModerationStatus

    @Field(key: .name)
    var name: String

    @Field(key: .description)
    var description: String

    @Field(key: .photoFileId)
    var photoFileId: String

    @Field(key: .city)
    var city: String

    @OptionalField(key: .adminComment)
    var adminComment: String?

    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?

    @OptionalField(key: .closedAt)
    var closedAt: Date?

    // MARK: - Initialization

    init() {}

    init(
        id: UUID? = nil,
        userId: UUID,
        status: ModerationStatus = .pending,
        name: String,
        description: String,
        photoFileId: String,
        city: String,
    ) {
        self.id = id
        $user.id = userId
        self.status = status
        self.name = name
        self.description = description
        self.photoFileId = photoFileId
        self.city = city
    }
}
