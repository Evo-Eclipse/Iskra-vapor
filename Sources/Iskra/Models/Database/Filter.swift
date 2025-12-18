import Fluent
import Foundation

/// User's search filter settings.
/// 1-to-1 relationship with User.
final class Filter: Model, @unchecked Sendable {
    static let schema = "filters"

    /// Uses user_id as primary key (1-to-1 relationship).
    /// No separate @Parent needed since id IS the foreign key.
    @ID(custom: .userId, generatedBy: .user)
    var id: UUID?

    @Field(key: .targetGenders)
    var targetGenders: [Gender]

    @Field(key: .ageMin)
    var ageMin: Int16

    @Field(key: .ageMax)
    var ageMax: Int16

    @Field(key: .lookingFor)
    var lookingFor: [LookingFor]

    // MARK: - Initialization

    init() {}

    init(
        userId: UUID,
        targetGenders: [Gender],
        ageMin: Int16,
        ageMax: Int16,
        lookingFor: [LookingFor]
    ) {
        self.id = userId
        self.targetGenders = targetGenders
        self.ageMin = ageMin
        self.ageMax = ageMax
        self.lookingFor = lookingFor
    }
}
