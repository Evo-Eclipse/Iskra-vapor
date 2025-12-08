import Fluent
import Foundation

/// User interaction action history.
/// Records likes, passes, messages (envelopes), and reports.
final class Interaction: Model, @unchecked Sendable {
    static let schema = "interactions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .actorId)
    var actorId: UUID

    @Field(key: .targetId)
    var targetId: UUID

    @Enum(key: .action)
    var action: InteractionAction

    @OptionalField(key: .message)
    var message: String?

    @Field(key: .isHidden)
    var isHidden: Bool

    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?

    // MARK: - Initialization

    init() {}

    init(
        id: UUID? = nil,
        actorId: UUID,
        targetId: UUID,
        action: InteractionAction,
        message: String? = nil,
        isHidden: Bool = false,
    ) {
        self.id = id
        self.actorId = actorId
        self.targetId = targetId
        self.action = action
        self.message = message
        self.isHidden = isHidden
    }
}
