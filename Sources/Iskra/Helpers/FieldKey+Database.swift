import Fluent

// MARK: - Shared Keys

extension FieldKey {
    /// Primary key identifier
    static var id: Self { "id" }
    /// Creation timestamp
    static var createdAt: Self { "created_at" }
    /// Update timestamp
    static var updatedAt: Self { "updated_at" }
    /// Closure/decision timestamp
    static var closedAt: Self { "closed_at" }
}

// MARK: - Users Table

extension FieldKey {
    static var telegramId: Self { "telegram_id" }
    static var telegramUsername: Self { "telegram_username" }
    static var birthDate: Self { "birth_date" }
    static var gender: Self { "gender" }
    static var status: Self { "status" }
    static var isMuted: Self { "is_muted" }
}

// MARK: - Profiles Table

extension FieldKey {
    static var userId: Self { "user_id" }
    static var displayName: Self { "display_name" }
    static var description: Self { "description" }
    static var photoFileId: Self { "photo_file_id" }
    static var city: Self { "city" }
}

// MARK: - Moderations Table

extension FieldKey {
    // userId already defined
    // status already defined
    static var name: Self { "name" }
    // description already defined
    // photoFileId already defined
    // city already defined
    static var adminComment: Self { "admin_comment" }
    // createdAt already defined
    // closedAt already defined
}

// MARK: - Filters Table

extension FieldKey {
    // userId already defined
    static var targetGenders: Self { "target_genders" }
    static var ageMin: Self { "age_min" }
    static var ageMax: Self { "age_max" }
    static var lookingFor: Self { "looking_for" }
}

// MARK: - Interactions Table

extension FieldKey {
    static var actorId: Self { "actor_id" }
    static var targetId: Self { "target_id" }
    static var action: Self { "action" }
    static var message: Self { "message" }
    static var isHidden: Self { "is_hidden" }
    // createdAt already defined
}

// MARK: - Matches Table

extension FieldKey {
    static var userAId: Self { "user_a_id" }
    static var userBId: Self { "user_b_id" }
    static var matchType: Self { "match_type" }
    // createdAt already defined
}
