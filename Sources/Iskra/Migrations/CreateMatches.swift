import Fluent
import SQLKit

/// Creates the matches table.
/// FK dependencies: users (user_a, user_b)
struct CreateMatches: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Match.schema)
            .id()
            .field(.userAId, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(.userBId, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(.matchType, .string, .required)
            .field(.createdAt, .datetime, .required)
            .unique(on: .userAId, .userBId)
            .create()

        // Create indexes and CHECK constraint
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("CREATE INDEX idx_matches_user_a_id ON matches(user_a_id)").run()
        try await sql.raw("CREATE INDEX idx_matches_user_b_id ON matches(user_b_id)").run()
        try await sql.raw("ALTER TABLE matches ADD CONSTRAINT chk_matches_user_order CHECK (user_a_id < user_b_id)").run()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Match.schema).delete()
    }
}
